#!/bin/bash


SSH_CONF_MAIN="/home/${USER}/.ssh"


SSH_DEPS=(ssh-keygen)


declare -A SSH_KEY_GEN_PARAM
SSH_KEY_GEN_PARAM=(
    key_type=''
    key_length=''
    key_path=''
    key_comment=''
    key_passwd=''
)


SSH_KEY_TYPE=(
    'ed25519'
    'rsa'
    'ecdsa'
)


SSH_RSA_KEY_LENGTH=(
    '3072'
    '4096'
)


SSH_ECDSA_KEY_LENGTH=(
    '256'
    '384'
    '521'
)


SSH_GEN_MODE_LIST=(
    'default mode (ed25519)'
    'manual'
)


# define error code
DEP_NOT_FOUND=1
SSH_KEY_NAME_INVAILD=2


function dir_is_exist {

    local dir="$1"

    return $([[ -d "$dir" ]])

}


function file_is_exist {

    local file="$1"

    return $([[ -f "$file" ]])

}


function ssh_services_is_exist {

    local deps="$1"

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            exit "$DEP_NOT_FOUND"
        fi
    done

}


function options_list_print {

    local list=("$@")

    for i in "${!list[@]}"; do

        printf '\t(%d). %s\n' \
            "$(( "$i" + 1 ))" \
            "${list[$i]}"

    done
}


function option_is_exist {

    local total="$1"

    local order="$2"

    return $([[ 0 < "$order" && "$order" -le "$total" ]])
}


function ssh_keygen_param_verify {

    local -n params_ref="$1"

    if [[ 
        -z "${params_ref[key_type]}" || \
        -z "${params_ref[key_length]}" || \
        -z "${params_ref[key_path]}" 
    ]]; then
        return 1
    fi

}


function ssh_key_default_params_builder {

    read -p "Please enter the name for generating the SSH key: " \
        key_name

    if [[ -z "$key_name" ]]; then
        echo 'Invalid SSH key name'
        exit "$SSH_KEY_NAME_INVAILD"
    fi

    ssh_key_abs_path="${SSH_CONF_MAIN}/${key_name}/${key_name}"

    echo "The default path for generating SSH keys is '${ssh_key_abs_path}'"

    mkdir -p "$(dirname "$ssh_key_abs_path")"

    SSH_KEY_GEN_PARAM[key_type]="ed25519"

    SSH_KEY_GEN_PARAM[key_length]="256"

    SSH_KEY_GEN_PARAM[key_path]="$ssh_key_abs_path"
}


function ssh_key_gen_params_builder {
    
    read -p "Please enter the name for generating the SSH key: " \
        key_name

    if [[ -z "$key_name" ]]; then
        echo 'Invalid SSH key name'
        exit "$SSH_KEY_NAME_INVAILD"
    fi

    ssh_key_abs_path="${SSH_CONF_MAIN}/${key_name}/${key_name}"

    echo "The default path for generating SSH keys is '${ssh_key_abs_path}'"

    mkdir -p "$(dirname "$ssh_key_abs_path")"

    SSH_KEY_GEN_PARAM[key_path]="$ssh_key_abs_path"

    local op_order=''

    while true; do

        options_list_print "${SSH_KEY_TYPE[@]}"

        read -p 'Please select the option number: ' op_order

        if option_is_exist "${#SSH_KEY_TYPE[@]}" "$op_order"; then

            SSH_KEY_GEN_PARAM[key_type]="${SSH_KEY_TYPE[$(( $op_order - 1 ))]}"

            break
        else
            echo 'Please select the correct option number.'
        fi
    
    done

    case "$op_order" in
    1)
        SSH_KEY_GEN_PARAM[key_length]=256
        ;;
    2)
        op_order=''

        while true; do
            options_list_print "${SSH_RSA_KEY_LENGTH[@]}"
            read -p 'Please select the option number: ' op_order

            if option_is_exist "${#SSH_RSA_KEY_LENGTH[@]}" "$op_order"; then

                SSH_KEY_GEN_PARAM[key_length]="${SSH_RSA_KEY_LENGTH[$(( $op_order - 1 ))]}"

                break
            else
                echo 'Please select the correct option number.'
            fi
        done
        ;;
    3)
        op_order=''
        while true; do
            options_list_print "${SSH_ECDSA_KEY_LENGTH[@]}"
            read -p Please select the option number. op_order

            if option_is_exist "${#SSH_ECDSA_KEY_LENGTH[@]}" "$op_order"; then

                SSH_KEY_GEN_PARAM[key_length]="${
                    SSH_ECDSA_KEY_LENGTH[$(( $op_order - 1 ))]
                }"

                break
            else
                echo 'Please select the correct option number.'
            fi
        done
        ;;
    esac

    read -p 'Please enter the comment content (default is ""): ' \
        SSH_KEY_GEN_PARAM[key_comment]

    read -p 'Please enter the password content (default is ""): ' \
        SSH_KEY_GEN_PARAM[key_passwd]

}


function ssh_key_generate {

    local -n params_ref="$1"

    ssh-keygen -t "${params_ref[key_type]}" \
        -b "${params_ref[key_length]}" \
        -f "${params_ref[key_path]}" \
        -C "${params_ref[key_comment]}" \
        -N "${params_ref[key_passwd]}"

}


function ssh_key_generate_mode_select {

    local op_order=''

    while true; do

        options_list_print "${SSH_GEN_MODE_LIST[@]}"

        read -p 'Please select the option number: ' op_order

        if option_is_exist "${#SSH_GEN_MODE_LIST[@]}" "$op_order"; then
            break
        else
            echo 'Please select the correct option number.'
        fi
    
    done

    case "$op_order" in
    1)
        ssh_key_default_params_builder
        ;;
    2)
        ssh_key_gen_params_builder
        ;;
    esac

    ssh_key_generate SSH_KEY_GEN_PARAM
}


function main {

    ssh_key_generate_mode_select

    if [[ "$?" == 0 ]]; then 
        echo 'Complete!'
    fi

}


main