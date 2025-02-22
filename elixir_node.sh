#!/bin/bash

tput reset
tput civis

# Put your logo here if nessesary

show_orange() {
    echo -e "\e[33m$1\e[0m"
}

show_blue() {
    echo -e "\e[34m$1\e[0m"
}

show_green() {
    echo -e "\e[32m$1\e[0m"
}

show_red() {
    echo -e "\e[31m$1\e[0m"
}

exit_script() {
    show_red "Скрипт остановлен (Script stopped)"
        echo ""
        exit 0
}

incorrect_option () {
    echo ""
    show_red "Неверная опция. Пожалуйста, выберите из тех, что есть."
    echo ""
    show_red "Invalid option. Please choose from the available options."
    echo ""
}

process_notification() {
    local message="$1"
    show_orange "$message"
    sleep 1
}

install_or_update_docker() {
    process_notification "Ищем Docker (Looking for Docker)..."
    if which docker > /dev/null 2>&1; then
        show_green "Docker уже установлен (Docker is already installed)"
        echo
        # Try to update Docker
        process_notification "Обновляем Docker до последней версии (Updating Docker to the latest version)..."

        if sudo apt install apt-transport-https ca-certificates curl software-properties-common -y &&
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" &&
            sudo apt-get update &&
            sudo apt-get install --only-upgrade docker-ce docker-ce-cli containerd.io docker-compose-plugin -y; then
            sleep 1
            echo -e "Обновление Docker (Docker update): \e[32mУспешно (Success)\e[0m"
            echo ""
        else
            echo -e "Обновление Docker (Docker update): \e[31мОшибка (Error)\e[0m"
            echo ""
        fi
    else
        # Install docker
        show_red "Docker не установлен (Docker not installed)"
        echo
        process_notification "\e[33mУстанавливаем Docker (Installing Docker)...\e[0m"

        if sudo apt install apt-transport-https ca-certificates curl software-properties-common -y &&
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" &&
        sudo apt-get update &&
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y; then
            sleep 1
            echo -e "Установка Docker (Docker installation): \e[32mУспешно (Success)\e[0m"
            echo
        else
            echo -e "Установка Docker (Docker installation): \e[31mОшибка (Error)\e[0m"
            echo
        fi
    fi
}

run_commands() {
    local commands="$*"

    if eval "$commands"; then
        sleep 1
        echo ""
        show_green "Успешно (Success)"
        echo ""
    else
        sleep 1
        echo ""
        show_red "Ошибка (Fail)"
        echo ""
    fi
}

run_commands_info() {
    local commands="$*"

    if eval "$commands"; then
        sleep 1
        echo ""
        show_green "Успешно (Success)"
        echo ""
    else
        sleep 1
        echo ""
        show_blue "Не найден (Not Found)"
        echo ""
    fi
}

run_node_command() {
    local commands="$*"

    if eval "$commands"; then
        sleep 1
        show_green "НОДА ЗАПУЩЕНА (NODE IS RUNNING)!"
        echo
    else
        show_red "НОДА НЕ ЗАПУЩЕНА (NODE ISN'T RUNNING)!"
        echo
    fi
}

stop_and_delete_container_image() {
    local container_name="$1"
    local image_name="$2"

    # Stop container
    process_notification "Останавливаем контейнер (Stopping container)..."
    run_commands_info "docker stop $container_name"

    # Delete container
    process_notification "Удаляем контейнер (Deleting container)..."
    run_commands_info "docker rm $container_name"

    # Delete image
    process_notification "Удаляем image (Deleting image)..."
    run_commands_info "docker rmi $image_name"
}

show_orange "  _______  __       __  ___   ___  __  .______ " && sleep 0.2
show_orange " |   ____||  |     |  | \  \ /  / |  | |   _  \ " && sleep 0.2
show_orange " |  |__   |  |     |  |  \  V  /  |  | |  |_)  | " && sleep 0.2
show_orange " |   __|  |  |     |  |   >   <   |  | |      / " && sleep 0.2
show_orange " |  |____ |   ----.|  |  /  .  \  |  | |  |\  \----. " && sleep 0.2
show_orange " |_______||_______||__| /__/ \__\ |__| | _|  ._____| " && sleep 0.2
echo
sleep 1

while true; do
    show_green "----- MAIN MENU -----"
    echo "1. Подготовка (Preparation)"
    echo "2. Установка Main/Test(Install)"
    echo "3. Elixir Testnet"
    echo "4. Elixir Mainnet"
    echo "5. Выход (Exit)"
    echo ""
    read -p "Выберите опцию (Select option): " option

    case $option in
        1)
            process_notification "Начинаем подготовку (Starting preparation)..."
            echo

            # Update packages
            process_notification "Обновляем пакеты (Updating packages)..."
            run_commands "sudo apt update && sudo apt upgrade -y && sudo apt install -y curl git jq lz4 build-essential unzip"

            # Install or update Docker
            install_or_update_docker

            echo
            show_green "--- ПОДГОТОВКА ЗАВЕРШЕНА. PREPARATION COMPLETED ---"
            echo
            ;;
        2)
            # install elixir
            process_notification "Начинаем установку (Starting installation)..."
            echo
            show_orange "Which Node?"
            echo "1. Testnet"
            echo "2. Mainnet"
            echo
            read -p "Выберите опцию (Select option): " option

            case $option in
                1)
                    ENV="testnet-3"
                    ELIXIR_MODE="elixir"
                    ;;
                2)
                    ENV="prod"
                    ELIXIR_MODE="elixir-mainnet"
                    ;;
                *)
                    incorrect_option
                    ;;
            esac

            # get data from user
            read -p "Введите имя валидатора (VALIDATOR NAME): " VALIDATOR_NAME
            read -p "Введите EVM адрес (EVM ADDRESS): " EVM_ADDRESS
            read -p "Введите приватный ключ EVM (EVM PRIVATE KEY): " EVM_PRIVATE_KEY

            SERVER_IP=$(hostname -I | awk '{print $1}')

            # donwload env
            process_notification "Скачиваем ENV (Downloading env)..."
            run_commands "mkdir -p $HOME/$ELIXIR_MODE && cd $HOME/$ELIXIR_MODE && wget https://files.elixir.finance/validator.env"

            # rewrite env with user data
            process_notification "Переписываем ENV (Rewriting env)..."
            echo
            if cat << EOF > validator.env
ENV=$ENV

STRATEGY_EXECUTOR_IP_ADDRESS=$SERVER_IP
STRATEGY_EXECUTOR_DISPLAY_NAME=$VALIDATOR_NAME
STRATEGY_EXECUTOR_BENEFICIARY=$EVM_ADDRESS
SIGNER_PRIVATE_KEY=$EVM_PRIVATE_KEY
EOF
            then
                sleep 1
                show_green "Успешно (Success)"
                echo
            else
                show_red "Ошибка (Error)"
                echo
            fi

            echo
            show_green "--- УСТАНОВКА ЗАВЕРШЕНА. INSTALLATION COMPLETED ---"
            echo
            ;;
        3)
            # TESTNET
            show_orange "▗▄▄▄▖▗▄▄▄▖ ▗▄▄▖▗▄▄▄▖▗▖  ▗▖▗▄▄▄▖▗▄▄▄▖" && sleep 0.2
            show_orange "  █  ▐▌   ▐▌     █  ▐▛▚▖▐▌▐▌     █  " && sleep 0.2
            show_orange "  █  ▐▛▀▀▘ ▝▀▚▖  █  ▐▌ ▝▜▌▐▛▀▀▘  █  " && sleep 0.2
            show_orange "  █  ▐▙▄▄▖▗▄▄▞▘  █  ▐▌  ▐▌▐▙▄▄▖  █  " && sleep 0.2
            echo
            sleep 1

            while true; do
                show_green "----- TESTNET MENU -----"
                echo "1. Запустить и обновить/остановить (Start and update/Stop)"
                echo "2. Проверить логи (Check logs)"
                echo "3. Удаление ноды (Delete node)"
                echo "4. О нодe (About Node)"
                echo "5. Назад (Back)"
                echo
                read -p "Выберите опцию (Select option): " option

                case $option in
                    1)
                        echo
                        echo "1. Запустить или обновить (Start or Update)"
                        echo "2. Остановить (Stop)"
                        echo
                        read -p "Выберите опцию (Select option): " option

                        case $option in
                            1)
                                # Start or update
                                stop_and_delete_container_image "elixir" "elixirprotocol/validator:v3-testnet"

                                # download docker image
                                process_notification "Скачиваем образ (Downloading image)..."
                                run_commands "docker pull elixirprotocol/validator:testnet --platform linux/amd64"

                                #Starting Node
                                process_notification "Запускаем ноду (Starting node)..."
                                run_node_command "sudo docker run -d --env-file /root/elixir/validator.env --name elixir --restart unless-stopped --platform linux/amd64 elixirprotocol/validator:testnet"
                                echo
                                ;;
                            2)
                                # Stop
                                stop_and_delete_container_image "elixir" "elixirprotocol/validator:v3-testnet"
                                echo
                                ;;
                            *)
                                incorrect_option
                                ;;
                        esac
                        ;;
                    2)
                        # check logs
                        process_notification "Запускаем логи (Starting the logs)..."
                        docker logs -f elixir
                        ;;
                    3)
                        # Delete node
                        stop_and_delete_container_image "elixir" "elixirprotocol/validator:v3-testnet"

                        # Delete folder
                        process_notification "Удаляем env (Deleting env)..."
                        run_commands_info "sudo rm -rvf $HOME/elixir/validator.env"

                        echo
                        show_green "--- НОДА УДАЛЕНА. NODE DELETED ---"
                        echo
                        ;;
                    4)
                        # Print node data
                        process_notification "Ищем данные ноды (Looking for node data)..."
                        sudo cat $HOME/elixir/validator.env
                        echo
                        ;;
                    5)
                        echo
                        break
                        ;;
                    *)
                    incorrect_option
                    ;;
                esac
            done
            ;;
        4)
            # MAINNET
            show_orange "▗▖  ▗▖ ▗▄▖ ▗▄▄▄▖▗▖  ▗▖▗▖  ▗▖▗▄▄▄▖▗▄▄▄▖" && sleep 0.2
            show_orange "▐▛▚▞▜▌▐▌ ▐▌  █  ▐▛▚▖▐▌▐▛▚▖▐▌▐▌     █  " && sleep 0.2
            show_orange "▐▌  ▐▌▐▛▀▜▌  █  ▐▌ ▝▜▌▐▌ ▝▜▌▐▛▀▀▘  █  " && sleep 0.2
            show_orange "▐▌  ▐▌▐▌ ▐▌▗▄█▄▖▐▌  ▐▌▐▌  ▐▌▐▙▄▄▖  █  " && sleep 0.2
            echo

            while true; do
                show_green "----- MAINNET MENU -----"
                echo "1. Запустить и обновить/остановить (Start and update/Stop)"
                echo "2. Проверить логи (Check logs)"
                echo "3. Удаление ноды (Delete node)"
                echo "4. О нодe (About Node)"
                echo "5. Назад (Back)"
                echo
                read -p "Выберите опцию (Select option): " option

                case $option in
                    1)
                        # OPERATING
                        echo
                        echo "1. Запустить или обновить (Start or Update)"
                        echo "2. Остановить (Stop)"
                        echo
                        read -p "Выберите опцию (Select option): " option

                        case $option in
                            1)
                                # Start or update
                                stop_and_delete_container_image "elixir_mainnet" "elixirprotocol/validator:latest"

                                # download docker image
                                process_notification "Скачиваем образ (Downloading image)..."
                                run_commands "docker pull elixirprotocol/validator:latest"

                                #Starting Node
                                process_notification "Запускаем ноду (Starting node)..."
                                run_node_command "sudo docker run -d --env-file /root/elixir-mainnet/validator.env --name elixir_mainnet --restart unless-stopped --platform linux/amd64 elixirprotocol/validator:latest"
                                echo
                                ;;
                            2)
                                # Stop
                                stop_and_delete_container_image "elixir_mainnet" "elixirprotocol/validator:latest"
                                echo
                                ;;
                            *)
                                incorrect_option
                                ;;
                        esac
                        ;;
                    2)
                        # logs
                        process_notification "Запускаем логи (Starting the logs)..."
                        docker logs -f elixir_mainnet
                        ;;
                    3)
                        # Delete node
                        stop_and_delete_container_image "elixir-mainnet" "elixirprotocol/validator:latest"

                        # Delete folder
                        process_notification "Удаляем env (Deleting env)..."
                        run_commands_info "sudo rm -rvf $HOME/elixir-mainnet/validator.env"

                        echo
                        show_green "--- НОДА УДАЛЕНА. NODE DELETED ---"
                        echo
                        ;;
                    4)
                        # Print node data
                        process_notification "Ищем данные ноды (Looking for node data)..."
                        sudo cat $HOME/elixir-mainnet/validator.env
                        echo
                        ;;
                    5)
                        echo
                        break
                        ;;
                    *)
                    incorrect_option
                    ;;
                esac
            done
            ;;
        5)
            # Stop script and exit
            exit_script
            ;;
        *)
            # incorrect options handling
            incorrect_option
            ;;
    esac
done
