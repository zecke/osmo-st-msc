GST_PACKAGE = gst-package
GST = gst

.PHONY: package image
all: package image

package:
	$(GST_PACKAGE) package.xml

image: package
	$(GST) -i -f Loader.st osmo_msc_ow2.img	
