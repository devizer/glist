echo -e "\n\n----------- Installing dotnet sdk 2.0.2 -----------" \
 && sudo apt-get update \
 && sudo apt-get -y install curl libunwind8 gettext apt-transport-https \
 && curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
 && sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
 && sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-jessie-prod jessie main" > /etc/apt/sources.list.d/dotnetdev.list' \
 && sudo apt-get update && apt-get install -y dotnet-sdk-2.0.3

