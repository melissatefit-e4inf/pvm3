date; hostname; uptime
lscpu | grep -E "Model name|^CPUs|Thread|Core|MHz"
free -h
uname -r; gcc --version | head -1; echo $PVM_ARCH
cat /sys/class/net/*/speed 2>/dev/null
ping -c 20 pc5201b | tail -2
