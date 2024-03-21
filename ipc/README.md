# Running validator node

## Prepare

Get IPC parameters, pull genesis file, create keys with one command:

```shell
./boostrap.sh --env ENV --name NAME --ip IP
```

See `./boostrap.sh -h` for more info.

## Ports used

- 8545 - chain RPC endpoint. Should be accessible by nox
- 26659 - fendermint p2p. Should be accessible from internet
- 26656 - cometbft p2p. Should be accessible from internet

## Run

```shell
docker compose up -d
```

## Cleanup

Delete contents of data and snapshots directories. Must be run with sudo right
since IPC runs as root and files on local fs are owned by root:

```shell
docker compose down
sudo rm -r cometbft/data/* fendermint/data/* fendermint/snapshots/*
```

Optionally you can delete contents of `keys/` directory. When you run
`bootstrap.sh` next time new pair of keys will be generated. Otherwise the keys
from previous deployment will be reused.

## Structure

```
.
├── bootstrap.sh  # script to bootstrap validator
├── cometbft
│   ├── config    # cometbft predefined config
│   └── data      # cometbft persistent data
├── docker-compose.yml
├── fendermint
│   ├── config    # fendermint prefidined config
│   ├── data      # fendermint persistent data
│   └── snapshots # fendermint snapshots
├── ipc-cli               # directory used by ipc cli to generate keys
│   ├── config.toml       # default ipc-cli config
│   └── evm_keystore.json # keysotre
├── keys
│   ├── fendermint.pk           # fendermint network public key
│   ├── fendermint.sk           # fendermint network private key
│   ├── priv_validator_key.json # validator keys in cometbft format
│   ├── validator.address       # validator address in eth format
│   ├── validator.pk            # validator public key
│   ├── validator.pk.hex        # validator publick key in hex format
│   ├── validator.sk            # validator secret key
│   └── validator.sk.hex        # validator secret key in hex format
└── README.md
```
