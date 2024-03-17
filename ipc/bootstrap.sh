#! /usr/bin/env bash

set -euo pipefail

cometbft_image="cometbft/cometbft:v0.37.x"
fendermint_image="fluencelabs/fendermint@sha256:5fd86d2c3124aab2c480f5029202378afaec90344eec01a126e05945016ea8bc"

help() {
script_name="$(basename $0)"
cat <<HELP
Usage: ${script_name} --env <ENV> --name <NAME> --ip <IP>
Bootstrap IPC validator node.

  --env   Environment where to run validator. Only dar is allowed for now
  --name  Human readable validator name.
  --ip    IP address where IPC p2p is accessible from the internet
HELP
}

generate_env() {
cat<<ENV > .env
FENDERMINT_IMAGE=${fendermint_image}
COMETBFT_IMAGE=${cometbft_image}
# chain name
FM_CHAIN_NAME="${subnet_name}"
# Subnet ID to connect to
FM_IPC__SUBNET_ID="${subnet_id}"
# Address of gateway contract
FM_IPC__TOPDOWN__PARENT_GATEWAY="${parent_gateway}"
# Address of registry contract
FM_IPC__TOPDOWN__PARENT_REGISTRY="${parent_registry}"
# Parent chain HTTP endpoint
FM_IPC__TOPDOWN__PARENT_HTTP_ENDPOINT="${parent_endpoint}"
# Address of a seed fendermint node
FM_RESOLVER__DISCOVERY__STATIC_ADDRESSES="${fendermint_seed}"
# fendermint gossip network name
FM_RESOLVER__NETWORK__NETWORK_NAME="${subnet_name}"
# Our subnet should never be flushed
FM_RESOLVER__MEMBERSHIP__STATIC_SUBNETS="${subnet_id}"

# Human readable validator node name. Will appear in logs
CMT_MONIKER="${name}"
# External address where cometbft P2P can be accessed from the internet
CMT_P2P_EXTERNAL_ADDRESS="${ip}:26656"
# List of cometbft seeds node that have information about all other nodes in a subnet
CMT_P2P_SEEDS="${cometbft_seeds}"
# List of cometbft nodes from which to perform state sync
CMT_STATESYNC_RPC_SERVERS="${cometbft_sync}"
# Block height to begin state sync from
CMT_STATESYNC_TRUST_HEIGHT="${trust_height}"
# Aformentioned block hash
CMT_STATESYNC_TRUST_HASH="${trust_hash}"
ENV
}

# Print help if no arguments provided
! (($#)) && help && exit 0

# Parse script arguments
while (($#)); do
  case "$1" in
  --env)
    env="$2"
    case "$env" in
    dar|test) shift 2 ;;
    *)
      echo "Unknown env '$2'."
      help
      exit 1
      ;;
    esac
    ;;
  --ip)
    ip="$2"
    if [[ ! $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      echo "$ip is not a valid IP4 address"
      exit 1
    fi
    shift 2
    ;;
  --name)
    name="$2"
    if [[ ! $name =~ ^[a-zA-Z0-9_-]+$ ]]; then
      echo "$name is invalid. Only [a-zA-Z0-9_-] are allowed"
      exit 1
    fi
    shift 2
    ;;
  -h|--help)
    help
    exit 0
    ;;
  *)
    echo "Unknown option '$1'."
    help
    exit 1
    ;;
  esac
done

# set variables according to environment
case "$env" in
  dar)
    echo TODO
    exit
  ;;
  test)
    # TODO pulling of contract addresses
    parent_gateway="0x097AcfFF25367aDa2C5110E9005f51E0E9685B3B"
    parent_registry="0xC5d8156A7021Eb1d9429aC91Ed6F4656F225a435"
    parent_endpoint="https://api.calibration.node.glif.io/rpc/v1"
    fendermint_seed="/dns4/fendermint.${env}.fluence.dev/tcp/26659/p2p/16Uiu2HAmQKdy7X6KRK2fAoMwVEdozfGSLwDQK15ptfTJRfKXqMwz"
    cometbft_seeds="2e1c1b8fd010d0e4dbbb00fb1c2b810587d95323@cometbft.${env}.fluence.dev:26656"
    cometbft_sync="https://cometbft.${env}.fluence.dev:443,https://cometbft.${env}.fluence.dev:443"
  ;;
esac

subnet_id="$(curl -s -f https://cometbft.${env}.fluence.dev/genesis | jq .result.genesis.app_state.chain_name -r)"
subnet_name="${subnet_id#/r*/}"
read trust_height trust_hash <<<$(curl -s -f https://cometbft.${env}.fluence.dev/commit | jq -r '.result.signed_header.header.height + " " + .result.signed_header.commit.block_id.hash')

curl -s -f https://cometbft.${env}.fluence.dev/genesis | jq .result.genesis > cometbft/config/genesis.json

generate_env

# check if validator key was already generated
if [[ -f ./keys/validator.sk ]]; then
  echo "Seems like validator key was already generated."
  echo "If you want to regenerate it cleanup ./keys directory and rerun the script."
  exit 0
fi

echo "Pulling fendermint container image"
docker pull ${fendermint_image}

echo "Generating fendermint key"
docker run --rm --user ${UID} -v ./keys:/keys ${fendermint_image} key gen --out-dir /keys/ --name fendermint

echo "Generating validator key"
validator_address=$(docker run --rm --user ${UID} -v ./ipc-cli:/ipc ${fendermint_image} ipc-cli --config-path /ipc/config.toml wallet new --wallet-type evm | tr -d \")
validator_public=$(docker run --rm --user ${UID} -v ./ipc-cli:/ipc ${fendermint_image} ipc-cli --config-path /ipc/config.toml wallet pub-key --wallet-type evm --address ${validator_address})
validator_private=$(docker run --rm --user ${UID} -v ./ipc-cli:/ipc -v ./keys:/keys ${fendermint_image} ipc-cli --config-path /ipc/config.toml wallet export --wallet-type evm --address ${validator_address} --hex)
echo $validator_address > ./keys/validator.address
echo $validator_public > ./keys/validator.pk.hex
echo $validator_private > ./keys/validator.sk.hex

echo "Converting validator key to fendermint format"
docker run --rm --user ${UID} -v ./keys:/keys ${fendermint_image} key eth-to-fendermint --secret-key /keys/validator.sk.hex --name validator --out-dir /keys

echo "Converting validator key to cometbft format"
docker run --rm --user ${UID} -v ./keys:/keys ${fendermint_image} key into-tendermint --secret-key /keys/validator.sk --out /keys/priv_validator_key.json

cat <<FINISH

Bootstrap finished successfully.
Subnet ID is ${subnet_id}
File with configuration options was generated at .env

Please share validator address and public key with Fluence team:
  address: ${validator_address}
  public key: ${validator_public}
You can also find them at './keys/validator.address' and './keys/validator.pk.hex'

Please run validator with:
docker-compose up -d
FINISH
