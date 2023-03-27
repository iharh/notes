if [[ "$OSTYPE" == "darwin"* ]]; then
    export SDKMAN_DIR="/Users/ihar_hancharenka/.sdkman"
    alias j-11='sdk u java 11.0.16-amzn'
else
    export SDKMAN_DIR="/home/iharh/.sdkman"
    alias j-11='sdk u java 11.0.12-open'
fi

[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

j-8() {
    sdk u java 8.332.08.1-amzn
}

alias j-17='sdk u java 17.0.4-amzn'

inst-sdkman() {
    curl -s "https://get.sdkman.io" | bash
}
