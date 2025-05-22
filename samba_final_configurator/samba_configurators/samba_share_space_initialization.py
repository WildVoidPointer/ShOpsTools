import os
import subprocess
import csv

SAMBA_REQUIRED_PACKAGES = ["samba", "smbclient"]
SAMBA_SHARE_SPACE_CSV_PATH = "./samba_share_depts_space.csv"
SAMBA_USERS_HOME_CSV_PATH = "./samba_share_users_space.csv"
SAMBA_USERGROUPS_DEFINE_FILE_PATH = "./samba_company_usergroups.txt"
SAMBA_USERS_CSV_PATH = "./samba_company_members.csv"
DEFAULT_USER_PASSWORD = "SambaPass123"


def run_command(command, check=True):
    """运行 shell 命令"""
    return subprocess.run(command, shell=True, check=check, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def check_required_packages(packages):
    for pkg in packages:
        result = subprocess.run(f"dpkg -s {pkg}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if result.returncode != 0:
            raise RuntimeError(f"Missing Samba dependency: {pkg}")


def create_usergroup(group: str):
    if not group:
        return
    if subprocess.run(f"getent group {group}", shell=True).returncode == 0:
        print(f"Group '{group}' already exists.")
        return
    subprocess.run(f"groupadd {group}", shell=True, check=True)
    print(f"Group '{group}' created.")


def initialize_user(username: str, password: str, groups: list[str]):
    if subprocess.run(f"id {username}", shell=True).returncode != 0:
        subprocess.run(f"useradd -m {username}", shell=True, check=True)
        print(f"User '{username}' created.")
    else:
        print(f"User '{username}' already exists.")

    for group in groups:
        if subprocess.run(f"getent group {group}", shell=True).returncode == 0:
            subprocess.run(f"usermod -aG {group} {username}", shell=True)
            print(f"Added user '{username}' to group '{group}'.")
        else:
            print(f"Warning: Group '{group}' does not exist for user '{username}'.")

    if subprocess.run(f"pdbedit -L | grep -qw '^{username}:'", shell=True).returncode != 0:
        subprocess.run(f"(echo '{password}'; echo '{password}') | smbpasswd -a -s {username}", shell=True, check=True)
        print(f"Samba user '{username}' added.")
    else:
        print(f"Samba user '{username}' already exists.")


def create_share_directory(owner: str, group: str, perms: str, path: str):
    if subprocess.run(f"id {owner}", shell=True).returncode != 0:
        print(f"Error: Owner '{owner}' does not exist.")
        return
    if subprocess.run(f"getent group {group}", shell=True).returncode != 0:
        print(f"Error: Group '{group}' does not exist.")
        return

    if not os.path.exists(path):
        os.makedirs(path)
        print(f"Created directory: {path}")
    else:
        print(f"Directory already exists: {path}")

    subprocess.run(f"chown {owner}:{group} {path}", shell=True)
    subprocess.run(f"chmod {perms} {path}", shell=True)


def create_dirs_from_csv(csv_path: str):
    with open(csv_path, newline='') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            if not row or row[0].strip().startswith("#"):
                continue
            owner, group, perms, path = map(str.strip, row[:4])
            create_share_directory(owner, group, perms, path)


def create_users_from_csv(csv_path: str, password: str):
    with open(csv_path, newline='') as f:
        for line in f:
            if not line.strip() or line.strip().startswith("#"):
                continue
            parts = [p.strip() for p in line.strip().split(",")]
            username = parts[0]
            groups = parts[1:]
            initialize_user(username, password, groups)


def create_usergroups_from_file(filepath: str):
    with open(filepath) as f:
        for line in f:
            if not line.strip() or line.strip().startswith("#"):
                continue
            groups = [grp.strip() for grp in line.strip().split(",")]
            for group in groups:
                create_usergroup(group)


def main():
    if os.geteuid() != 0:
        raise PermissionError("This script must be run as root!")

    check_required_packages(SAMBA_REQUIRED_PACKAGES)
    create_usergroups_from_file(SAMBA_USERGROUPS_DEFINE_FILE_PATH)
    create_users_from_csv(SAMBA_USERS_CSV_PATH, DEFAULT_USER_PASSWORD)
    create_dirs_from_csv(SAMBA_SHARE_SPACE_CSV_PATH)
    create_dirs_from_csv(SAMBA_USERS_HOME_CSV_PATH)


if __name__ == "__main__":
    main()
