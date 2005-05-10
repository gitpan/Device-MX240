use Test;
BEGIN { plan tests => 1 };
# Why does this try to load from the install base and not blib?

use Device::MX240;

#my $d = Device::MX240::open_dev();

#open(STDERR,">test.log");
#require Data::Dumper;
#print STDERR Data::Dumper->Dump([$d]);

#$d->close_dev();

ok(1);

