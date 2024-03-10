# Running validator node

## Prepare

- Copy env template file and change placeholders to real values:

```shell
cp template.env .env
```

- Generate fendermint network key:

```shell
docker run --rm --user ${UID} -v ./keys:/keys fluencelabs/fendermint key gen --out-dir /keys/ --name network
```

- Create key validator wallet (not sure about this and following parts):

```shell
docker run --rm --user ${UID} -v ./ipc-cli:/ipc ghcr.io/consensus-shipyard/fendermint ipc-cli --config-path /ipc/config.toml wallet new --wallet-type evm
```

- Export validator key. Make sure to change `<address>` to address from previous
  step:

```shell
docker run --rm --user ${UID} -v ./ipc-cli:/ipc -v ./keys:/keys ghcr.io/consensus-shipyard/fendermint ipc-cli --config-path /ipc/config.toml wallet export --wallet-type evm --address <address> --hex > ./keys/validator.eth
```

- Convert validator key to fendermint format:

```shell
docker run --rm --user ${UID} -v ./keys:/keys fluencelabs/fendermint key eth-to-fendermint --secret-key /keys/validator.eth --name validator --out-dir /keys
```

- Convert validator key to cometbft format:

```shell
docker run --rm --user ${UID} -v ./keys:/keys fluencelabs/fendermint key into-tendermint --secret-key /keys/validator.sk --out /keys/priv_validator_key.json
```

## Run

```shell
DOCKER_UID=$(id -u) docker compose up -d
```
