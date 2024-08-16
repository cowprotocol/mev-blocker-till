# Formal Verification

This subdirectory contains a formal verification specification for the MEVBlocker till contract.

## Requirements

Note that all commands are executed from the root of the repository.

Make sure that the Certora CLI tool is installed:

```sh
python3 -m venv venv
source venv/bin/activate
pip install -r certora/requirements.txt
```

Additionally, the Solidity compiler must also be installed in order compile the contracts:

```sh
curl -L https://github.com/ethereum/solidity/releases/download/v0.8.25/solc-static-linux -o /some/directory/in/path/solc-0.8.25
chmod +x /some/directory/in/path/solc-0.8.25
```

And finally, make sure that your Certora API key is correctly configured:

```sh
export CERTORAKEY="..."
```

## Verfying the Specification

```sh
certoraRun certora/conf/MevblockerFeeTill.conf
```
