# This patch disables stateful partition encryption (which does not work with swtpm since r103)

ret=0

mv /roota/usr/sbin/mount-encrypted /roota/usr/sbin/mount-encrypted.real
cat >/roota/usr/sbin/mount-encrypted <<'MOUNTS'
#!/bin/bash
#touch /test
#echo "mount-encrypted called with args \"$@\"" >> /test
if [ $# -eq 0 ] && [ ! -f /mnt/stateful_partition/factory_install_reset ]; then
	/usr/sbin/mount-encrypted.real
	umount /home/chronos
	umount /var
	umount /mnt/stateful_partition/encrypted
	rm -f /mnt/stateful_partition/encrypted.*
	mount --bind /mnt/stateful_partition/encrypted /mnt/stateful_partition/encrypted
	mkdir -p  /mnt/stateful_partition/encrypted/chronos /mnt/stateful_partition/encrypted/var
	mount --bind /mnt/stateful_partition/encrypted/var /var
	chown chronos:chronos /mnt/stateful_partition/encrypted/chronos
	mount --bind /mnt/stateful_partition/encrypted/chronos /home/chronos
else
	/usr/sbin/mount-encrypted.real "$@"
fi
MOUNTS
chmod 0755 /roota/usr/sbin/mount-encrypted
if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 0))); fi

exit $ret
