#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <hid.h>


// vendor and product id for MX240a base station
#define MX240A_VENDOR 0x22b8
#define MX240A_PRODUCT 0x7f01

// usage path for libhid
unsigned char const PATHLEN = 2;
int const PATH_OUT[][2] = { { 0xff000001, 0xff000001 }, { 0xff000001, 0xff000002 } };
int const READ_SIZE = 16;
int const WRITE_SIZE = 16;

static SV *open_dev			( void );
static SV *read_dev			( SV* device );
static SV *write_dev		( SV* device, char* buf );
static SV *close_dev		( SV* device );

/* read up to READ_SIZE from device hid */
SV*
read_dev ( SV* device ) {
	HIDInterface* hid;
	unsigned char data[READ_SIZE];
	int ret;
	
	if (SvROK( device )) {
		device = SvRV( device );
	}

	hid = (HIDInterface*) SvIV( device );
	
	if (!hid) {
		return &PL_sv_undef;
	}
	
	ret = usb_interrupt_read( hid->dev_handle, 0x81, data, READ_SIZE, 500 );
	if (ret > 0) {
//		print_data(data,ret);
		return newSVpv(data,ret);
	}
	
	return &PL_sv_undef;
}

/* write up to WRITE_SIZE to device hid */
SV*
write_dev ( SV* device, char* buf ) {
    HIDInterface*	hid;
    int ret;
	int rett;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	hid = (HIDInterface*) SvIV( device );
	
	if (!hid) {
		return &PL_sv_undef;
	}
	
    ret = hid_set_output_report(hid, PATH_OUT[0], PATHLEN, buf, WRITE_SIZE/2);
    if ( ret < 0 ) return newSViv( (IV) 0 );
	
    rett = hid_set_output_report(hid, PATH_OUT[1], PATHLEN, buf + WRITE_SIZE/2, WRITE_SIZE/2);
    if ( rett < 0 ) return newSViv( (IV) 0 );
	
    return newSViv( (IV) rett );
}

/* open a usb hid device, returns a blessed object */
SV*
open_dev ( void ) {
    hid_return ret;
    HIDInterface* hid;
   	SV*		blessed_device;
    
    HIDInterfaceMatcher matcher = { MX240A_VENDOR, MX240A_PRODUCT, NULL, NULL, 0 };

    ret = hid_init();

    if (ret != HID_RET_SUCCESS) {
        fprintf(stderr, "init failed with return code %d\n", ret);
		return &PL_sv_undef;
    }

    hid = hid_new_HIDInterface();
    if (hid == 0) {
        fprintf(stderr, "hid_new_HIDInterface() failed, out of memory?\n");
		return &PL_sv_undef;
    }

    ret = hid_force_open(hid, 0, &matcher, 3);
    if (ret != HID_RET_SUCCESS) {
        fprintf(stderr, "hid_force_open failed with return code %d\n", ret);
        if( ret == 12 ) fprintf(stderr, "Do you have read/write permissions to the usbfs (/proc/bus/usb)?\n");
		return &PL_sv_undef;
    }
	
	blessed_device = newSViv( (IV) hid );

	blessed_device = sv_bless(newRV_noinc(blessed_device), gv_stashpv("Device::MX240", FALSE));

	return blessed_device;
}

/* close a HIDInterface */
/* close_dev (HIDInterface * hid) {*/
SV*
close_dev ( SV* device ) {
    HIDInterface* hid;
    hid_return ret;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	hid = (HIDInterface*) SvIV( device );
	
	if (!hid) {
		return &PL_sv_undef;
	}
	
    // clean up
    ret = hid_close(hid);
    if (ret != HID_RET_SUCCESS) {
        fprintf(stderr, "hid_close failed with return code %d\n", ret);
		return newSViv( (IV) 0 );
    }

    hid_delete_HIDInterface(&hid);

    ret = hid_cleanup();
    if (ret != HID_RET_SUCCESS) {
        fprintf(stderr, "hid_cleanup failed with return code %d\n", ret);
		return newSViv( (IV) 0 );
    }
	
	return newSViv( (IV) 1 );
}

/* --------------------------- end of libimfree api ----------------------------- */

/* print array in hex (used for testing) */
void
print_data( unsigned char* data, int len ) {
    int i;
    int tmp;
    for ( i = 0; i < len; i++ ) printf( "%.2x ", data[i] );
/*    printf("    ");
    i = 0;
    for ( i = 0; i < len; i++ ) {
        tmp = data[i];
        if( tmp < 32 || tmp > 126 ) tmp = 46;
        printf("%d");
    } */
    printf("\n");
}

/* opcodes for output */
/*
* unsigned char const op_init[] = { 3, 0xad, 0xef, 0x8d };
* unsigned char const op_poll[] = { 1, 0xad };
* unsigned char const op_msgout [] = { 1, 0x80 };
* c1 d7 20 41 49 4d 20 20 ff 00
*      |    A  I  M
* bool done = false;
**/

/**************** Perl Stubs ****************/

MODULE = Device::MX240		PACKAGE = Device::MX240


SV*
open_dev ( )
	OUTPUT:
		RETVAL

SV*
read_dev ( device )
	SV * device
	OUTPUT:
		RETVAL

SV*
write_dev ( device, buf )
	SV * device
	char* buf
	OUTPUT:
		RETVAL

SV*
close_dev ( device )
	SV * device
	OUTPUT:
		RETVAL

