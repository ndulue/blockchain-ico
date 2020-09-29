export default function ether (n) {
    return new web3.BigNumber(wei.toWei(n, 'ether'));
}