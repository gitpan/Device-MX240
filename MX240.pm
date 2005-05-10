package Device::MX240;

#use 5.006;
use strict;
use warnings;
use Errno;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our $VERSION = '0.04';

our @ISA = qw(Exporter DynaLoader);

# This allows declaration use Device::MX240 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	open_dev
	MX240A_VENDOR
	MX240A_PRODUCT
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

sub AUTOLOAD {
	# This AUTOLOAD is used to 'autoload' constants from the constant()
	# XS function.  If a constant is not found then control is passed
	# to the AUTOLOAD in AutoLoader.

	my $constname;
	our $AUTOLOAD;
	($constname = $AUTOLOAD) =~ s/Device::MX240:://;
	croak "&$_[0] not defined in Device::MX240" if $constname eq 'constant';
	my $val = constant($constname, @_ ? $_[0] : 0);
	if ($! != 0) {
		if ($!{EINVAL}) {
		    $AutoLoader::AUTOLOAD = $AUTOLOAD;
		    goto &AutoLoader::AUTOLOAD;
		} else {
		    croak "Your vendor has not defined Device::MX240 macro $constname";
		}
	}
	{
		no strict 'refs';
		# Fixed between 5.005_53 and 5.005_61
		if ($] >= 5.00561) {
		    *$AUTOLOAD = sub () { $val };
		} else {
		    *$AUTOLOAD = sub { $val };
		}
	}
	goto &$AUTOLOAD;
}

Device::MX240->bootstrap($VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Device::MX240 - Perl api to the MX240 (Motorola Instant Messenger)

=head1 SYNOPSIS

	use Device::MX240 qw(open_dev);

	my $done = 0;

	# Ctrl-C/INT handler
	$SIG{INT} = sub { $SIG{INT} = 'IGNORE'; $done++; };

	my $d = open_dev();

	# init device
	$d->write_dev("\xad\xef\x8d");

	while (!$done) {
		my $buf = $d->read_dev();
		if ($buf) {
			# process $buf
			# and use $d->write_dev();
		}
		sleep(1);
		# poll the device
		$d->write_dev("\xad");
	}

	$d->close_dev;

	exit;

=head1 ABSTRACT

This module allows easy communication to and from the MX240.  Also known
as the IMFree.  The device is a wireless instant messenger.
(USB base, 900mhz) libusb and libhid are required for this module to
compile.

=head1 DESCRIPTION

This module has a few functions to interact with the MX240a.  Data is read in
16 byte boundries, and is written in 16 byte boundries.

=head2 CONSTRUCTOR

=over 4

=item C<open_dev>

This function returns a blessed reference to the MX240 device.  The interface
for this function may change in the future to accept a vendor and product id.
You can use the returned object with the following mehods.

=back

=head2 METHODS

=over 4

=item C<read_dev>

	Returns undef when nothing has been read, and 16 bytes of data on success.

=item C<write_dev( $data )>

	Returns number of bytes written, and 0 on failure.

=item C<close_dev>

	Returns true on success and 0 on failure;

=back

=head2 EXPORTS

None by default.  You can export C<open_dev>, C<MX240A_VENDOR>, and C<MX240A_PRODUCT>.

	use Device::MX240 qw(open_dev);

=head1 SEE ALSO

L<http://libusb.sourceforge.net/>, L<http://libhid.alioth.debian.org/>

=head1 AUTHOR

David Davis E<lt>xantus@cpan.orgE<gt>

=head1 CREDITS

Dusty, for the C functions to libhid and libusb.

Please rate this module. L<"http://cpanratings.perl.org/rate/?distribution=Device-MX240">

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by David Davis and Teknikill Software

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
