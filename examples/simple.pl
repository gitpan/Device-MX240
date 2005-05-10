#!/usr/bin/perl

# lame test script!

use strict;

my $unit = 1;

# spaces are auto removed
my $INIT = "ad ef 8d 00 00 00 00 00 00 00 00 00 00 00 00 00";
my $POLL = "ad 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00";
my $SRVN = "c%d d7 20 41 49 4d 20 20 ff 00 00 00 00 00 00 00";

use Device::MX240;
use bytes;

my $done = 0;

$SIG{INT} = sub {
	print "closing\n";
	$SIG{INT} = 'IGNORE';
	$done = 1;
};

my $d = Device::MX240::open_dev();

sleep(2);
print "device init...";
my $i = $d->write_dev(hex2bin($INIT));
print STDERR "out: $INIT\n";
sleep(1);

my $hid;
my $msg = '';
my $m = 0;
while (!$done) {
	my $buf = $d->read_dev();
	my $len = length($buf);
	my $r;
	if ($len > 0) {
		print "len:$len\n";
		my $h = bin2hex($buf);
		# stupid case
		$h = "f$m $h" if ($m);
		print STDERR "in: ".bin2hex($buf)."\n";
		if ($h =~ m/^e\d fd/) {
			print "ack\n";
		} elsif ($h =~ m/^f\d fd/) {
			print "unknown\n";
		} elsif ($h =~ m/^f\d 8e ff/) {
			# disconnect
			print "disconnect\n";
		} elsif ($h =~ m/^f\d 8e/) {
			# connect
			print "connect\n";
			$r = $d->write_dev(hex2bin(sprintf($SRVN,$unit)));
			print STDERR "out: ".sprintf($SRVN,$unit)." <- srvname\n";
#			$unit++;
		} elsif ($h =~ m/^f\d 91/) {
			# user
			print "user\n";
		} elsif ($h =~ m/^f(\d) 92/) {
			# pass
			print "pass\n";
			# login ok
			$r = $d->write_dev(hex2bin("e$1 d3 00 00 00 00 00 00 00 00 00 00 00 00 00 00"));
			print STDERR "out: e0 d3 00 00 00 00 00 00 00 00 00 00 00 00 00 00 <- login ok\n";
			sleep(1);
			# newpsn
			# this may be wrong..
			# e1 ca 41 4e 4e 01 00 00
			$r = $d->write_dev(hex2bin("e$1 ca 41 4e 4e 01 00 00 00 00 00 00 00 00 00 00"));
			print STDERR "out: e0 ca 41 4e 4e 01 00 00 00 00 00 00 00 00 00 00 <- newpsn\n";
			# psndata TEST
			# MPD data:
			# c1 c9 4d 50 44 20 20 20
			# 4d 50 44 ff 00 00 00 00
			$r = $d->write_dev(hex2bin("c$1 c9 54 45 53 54 20 20 54 45 53 54 20 00 00 00"));
			print STDERR "out: c$1 c9 54 45 53 54 20 20 54 45 53 54 20 00 00 00 <- psndata\n";	
			
		} elsif ($h =~ m/^f(\d) 94/) {
			# talk
			print "talk!! $1\n";
			$hid = $1;
			my $dat = hex2bin("8$hid 01 00 ".bin2hex("hello")." ff");
			print "out: $dat : ".bin2hex($dat)."\n";
			$d->write_dev($dat);
		} elsif ($h =~ m/^f\d 95/) {
			# bye
			print "bye\n";
		} elsif ($h =~ m/^0e ce/) {
			# logoff
			print "logoff\n";
		} elsif ($h =~ m/^f\d 9b/) {
			# chat
			print "chat\n";
		} elsif ($h =~ m/^e0 ce/) {
			# pres
			print "pres\n";
			$r = $d->write_dev(hex2bin("ee d3 00 00 00 00 00 00 00 00 00 00 00 00 00 00"));
			print STDERR "out: ee d3 00 00 00 00 00 00 00 00 00 00 00 00 00 00 <- ? pres ok\n";
			sleep(1);
			$r = $d->write_dev(hex2bin(sprintf($SRVN,$unit)));
			print stderr "out: ".sprintf($SRVN,$unit)." <- srvname\n";
			$unit++;
		} elsif ($h =~ m/^f\d 8c/) {
			# connect fail
			print "connect fail\n";
		} elsif ($hid && $h =~ m/^f(\d)(.*)/) {
			my $hid = $1;
			# d1 31 31 31 31 31 31 31 31 31 31 31 31 31 31 31
			# 31 31 31 31 31 31 31 31 31 31 31 31 31 31 31 fe
			# d1 31 31 31 31 31 31 31 31 31 31 31 31 31 31 31
			# 31 31 31 31 31 31 31 31 31 31 31 31 31 31 31 fe
			# f1 31 31 31 31 31 31 31 31 31 31 ff fe 00 31 31
			# msgin / not ff?
			print "msg in\n";
			my $txt = $2;
			if ($txt =~ s/ff.*//) {
				$m = 0;
				$txt = $msg.hex2bin($txt);
			} else {
				$m = $hid;
				$msg .= hex2bin($txt);
				next;
			}
			
			print "msg: [".$txt."]\n";
			# msgout:N|[id]:[warn]:[message]
			# 81 02 00 68 65 6c 6c 6f
			# 20 77 6f 72 6c 64 ff
			my $dat = hex2bin("8$hid 01 00 ".bin2hex($txt)." ff 00");
			print "out: $dat : ".bin2hex($dat)."\n";
			$d->write_dev($dat);
		} elsif ($h =~ m/^ef 01 01 fe/) {
			# init ok
			print "init ok\n";
		}
		
		if ($r) { print "write: $r\n"; }
	}
	sleep(1);
	my $n = $d->write_dev(hex2bin($POLL));
#	print STDERR "out: $POLL\n";
#	print "poll write: $n\n";
}

$d->close_dev();

print "clean exit\n";

exit 0;

sub hex2bin {
	my $todecode = shift;
	$todecode =~ s/\s+//g;
	$todecode =~ s/([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
	return $todecode;
}

sub bin2hex {
	my ($d) = @_;
	$d =~ s/(.)/sprintf("%02x ",ord($1))/egs;
	return $d;
}

