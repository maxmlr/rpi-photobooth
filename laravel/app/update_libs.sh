#!/bin/sh

# methods to load external js and css
get_zip() {
    echo "retrieving $1"
    mkdir /tmp/_get
    curl -s -o /tmp/_get/master.zip -L $1
    unzip -q /tmp/_get/master.zip -d /tmp/_get
    for arg in "${@:2}"
    do
        from=`echo ${arg/:*/ }`
        to=`echo ${arg/*:/ }`
        echo "copying $from to $to"
        find /tmp/_get -name $from -exec cp -rf {} $to  \;
    done
    rm -rf /tmp/_get
}

get_js() {
    from=$1
    to=$2
    echo "retrieving $from to $to"
    curl -s -L $from -o $to
}

cp_from() {
    from=$1
    to=$2
    echo "copying $from to $to"
    cp $from $to
}

# # jQuery
# cp_from vendor/components/jquery/jquery.min.js public/vendor/rpi-photobooth-manager/js/jquery.min.js
# # kegg
# get_js http://www.kegg.jp/js/dhtml.js public/vendor/rpi-photobooth-manager/js/dhtml.js
# # html2canvas
# get_js https://github.com/niklasvh/html2canvas/releases/download/v1.0.0-alpha.2/html2canvas.min.js public/vendor/rpi-photobooth-manager/js/html2canvas.min.js
# # resumable.js
# get_zip https://github.com/23/resumable.js/archive/master.zip resumable.js:public/vendor/rpi-photobooth-manager/js
# # lodash
# get_zip https://github.com/lodash/lodash/archive/4.17.4.zip lodash.min.js:public/vendor/rpi-photobooth-manager/js
# # bootstrap 4
# get_zip https://github.com/twbs/bootstrap/archive/v4.0.0.zip bootstrap.min.js*:public/vendor/rpi-photobooth-manager/js dropdown.js*:public/vendor/rpi-photobooth-manager/js bootstrap.min.css*:public/vendor/rpi-photobooth-manager/css
# # bootstrap-colorpicker
# get_zip https://github.com/itsjavi/bootstrap-colorpicker/releases/download/3.1.2/bootstrap-colorpicker-v3.1.2-dist.zip js*:public/vendor/bootstrap-colorpicker css:public/vendor/bootstrap-colorpicker
# # bootstrap-waitingfo
# get_zip https://github.com/ehpc/bootstrap-waitingfor/archive/master.zip bootstrap-waitingfor.min.js:public/vendor/rpi-photobooth-manager/js
# # bootstrap-select
# get_zip https://github.com/silviomoreto/bootstrap-select/archive/v1.12.4.zip bootstrap-select.min.js:public/vendor/rpi-photobooth-manager/js bootstrap-select.js.map:public/vendor/rpi-photobooth-manager/js bootstrap-select.min.css:public/vendor/rpi-photobooth-manager/css
# # bootstrap-dialog
# get_zip https://github.com/nakupanda/bootstrap3-dialog/archive/v1.35.4.zip bootstrap-dialog.min.js:public/vendor/rpi-photobooth-manager/js bootstrap-dialog.min.css:public/vendor/rpi-photobooth-manager/css
# # tether
# get_zip http://github.com/HubSpot/tether/archive/v1.3.3.zip tether.min.js:public/vendor/rpi-photobooth-manager/js tether.min.css:public/vendor/rpi-photobooth-manager/css
# # datatables + bootstrap 4
# # get_zip https://datatables.net/download/builder?bs4/jszip-2.5.0/pdfmake-0.1.32/dt-1.10.16/b-1.5.1/b-colvis-1.5.1/b-html5-1.5.1/b-print-1.5.1/r-2.2.1 datatables.min.js:public/vendor/rpi-photobooth-manager/js datatables.min.css:public/vendor/rpi-photobooth-manager/css
# get_zip https://datatables.net/download/builder?bs4/jszip-2.5.0/pdfmake-0.1.36/dt-1.10.20/b-1.6.1/b-colvis-1.6.1/b-html5-1.6.1/b-print-1.6.1/r-2.2.3 datatables.min.js:public/vendor/rpi-photobooth-manager/js datatables.min.css:public/vendor/rpi-photobooth-manager/css
# # datatables + pdf-make
# get_zip https://github.com/bpampuch/pdfmake/archive/0.1.32.zip pdfmake.min.js.map:public/vendor/rpi-photobooth-manager/js 
# # popper
# get_zip https://github.com/FezVrasta/popper.js/archive/v1.12.9.zip popper.js:public/vendor/rpi-photobooth-manager/js popper.js.map:public/vendor/rpi-photobooth-manager/js
# # qtip
# get_js https://cdn.jsdelivr.net/qtip2/3.0.3/jquery.qtip.min.js public/vendor/rpi-photobooth-manager/js/jquery.qtip.min.js
# get_js https://cdn.jsdelivr.net/qtip2/3.0.3/jquery.qtip.min.css public/vendor/rpi-photobooth-manager/css/jquery.qtip.min.css
# # fontawsome
# get_zip https://use.fontawesome.com/releases/v5.0.1/fontawesome-free-5.0.1.zip fontawesome-all.min.js:public/vendor/rpi-photobooth-manager/js fa-svg-with-js.css:public/vendor/rpi-photobooth-manager/css
# # slick
# get_zip https://github.com/kenwheeler/slick/archive/1.8.0.zip slick.min.js:public/vendor/rpi-photobooth-manager/js slick.css:public/vendor/rpi-photobooth-manager/css slick-theme.css:public/vendor/rpi-photobooth-manager/css
# # d3
# get_zip https://github.com/d3/d3/releases/download/v4.12.2/d3.zip d3.min.js:public/vendor/rpi-photobooth-manager/js
# # moment
# get_js http://momentjs.com/downloads/moment.js public/vendor/rpi-photobooth-manager/js/moment.js
