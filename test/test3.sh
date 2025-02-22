declare -A CONF_PARAMETER_DICT

function parameters_extractor() {
    ORIGIN_IFS=$IFS
    SECTION_KEY=""
    while IFS= read -r line; do

        if echo "$line" | grep -qE '^#.*'; then
            continue

        elif echo "$line" | grep -qE '^\[.*\]'; then
            SECTION_KEY=$(echo "$line" | xargs)

        elif echo "$line" | grep -qE '.*=.*'; then
            # key=$(echo "$line" | cut -d'=' -f1 | xargs)
            # value=$(echo "$line" | cut -d'=' -f2- | xargs)

            CONF_PARAMETER_DICT["$SECTION_KEY"]+="$line"
        fi
    done < "$1"
}


parameters_extractor "config.ini"


for key in "${!CONF_PARAMETER_DICT[@]}"; do
    echo "$key = ${CONF_PARAMETER_DICT[$key]}"
done

echo $CONF_PARAMETER_DICT[]
