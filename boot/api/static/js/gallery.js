var $grid;

function getUrlParameter(sParam) {
    var sPageURL = window.location.search.substring(1),
        sURLVariables = sPageURL.split('&'),
        sParameterName,
        i;

    for (i = 0; i < sURLVariables.length; i++) {
        sParameterName = sURLVariables[i].split('=');

        if (sParameterName[0] === sParam) {
            return sParameterName[1] === undefined ? true : decodeURIComponent(sParameterName[1]);
        }
    }
};

var fancybox_defaults = {
    selector: '.grid a:visible',
    keyboard: true,
    infobar: false,
    loop: false,
    gutter: 50,
    onActivate: function (instance, slide) {
        $("[data-morphing]").fancyMorph({
            hash: 'morphing'
        });
    },
    afterShow: function (instance, slide) {
        $('.pb-share').data('src', '/api/qrcode.php?filename=' + $(slide.opts.$orig).data('name'));
    },
    buttons: [
        "pbShare",
        //"share",
        "slideShow",
        "thumbs",
        "close",
    ],
    baseTpl: '<div class="fancybox-container" role="dialog" tabindex="-1">' +
        '<div class="fancybox-bg"></div>' +
        '<div class="fancybox-inner">' +
        '<div class="fancybox-infobar"><span data-fancybox-index></span>&nbsp;/&nbsp;<span data-fancybox-count></span></div>' +
        '<div class="fancybox-toolbar">{{buttons}}</div>' +
        '<div class="fancybox-navigation">{{arrows}}</div>' +
        '<div class="fancybox-stage"></div>' +
        '<div class="fancybox-caption"><div class=""fancybox-caption__body"></div></div>' +
        '</div>' +
        '</div>',
    btnTpl: {
        download: '<a download data-fancybox-download class="fancybox-button fancybox-button--download" title="{{DOWNLOAD}}" href="javascript:;">' +
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M18.62 17.09V19H5.38v-1.91zm-2.97-6.96L17 11.45l-5 4.87-5-4.87 1.36-1.32 2.68 2.64V5h1.92v7.77z"/></svg>' +
            "</a>",

        zoom: '<button data-fancybox-zoom class="fancybox-button fancybox-button--zoom" title="{{ZOOM}}">' +
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M18.7 17.3l-3-3a5.9 5.9 0 0 0-.6-7.6 5.9 5.9 0 0 0-8.4 0 5.9 5.9 0 0 0 0 8.4 5.9 5.9 0 0 0 7.7.7l3 3a1 1 0 0 0 1.3 0c.4-.5.4-1 0-1.5zM8.1 13.8a4 4 0 0 1 0-5.7 4 4 0 0 1 5.7 0 4 4 0 0 1 0 5.7 4 4 0 0 1-5.7 0z"/></svg>' +
            "</button>",

        close: '<button data-fancybox-close class="fancybox-button fancybox-button--close" title="{{CLOSE}}">' +
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 10.6L6.6 5.2 5.2 6.6l5.4 5.4-5.4 5.4 1.4 1.4 5.4-5.4 5.4 5.4 1.4-1.4-5.4-5.4 5.4-5.4-1.4-1.4-5.4 5.4z"/></svg>' +
            "</button>",

        // Arrows
        arrowLeft: '<button data-fancybox-prev class="fancybox-button fancybox-button--arrow_left" title="{{PREV}}">' +
            '<div><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M11.28 15.7l-1.34 1.37L5 12l4.94-5.07 1.34 1.38-2.68 2.72H19v1.94H8.6z"/></svg></div>' +
            "</button>",

        arrowRight: '<button data-fancybox-next class="fancybox-button fancybox-button--arrow_right" title="{{NEXT}}">' +
            '<div><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M15.4 12.97l-2.68 2.72 1.34 1.38L19 12l-4.94-5.07-1.34 1.38 2.68 2.72H5v1.94z"/></svg></div>' +
            "</button>",

        // This small close button will be appended to your html/inline/ajax content by default,
        // if "smallBtn" option is not set to false
        smallBtn: '<button type="button" data-fancybox-close class="fancybox-button fancybox-close-small" title="{{CLOSE}}">' +
            '<svg xmlns="http://www.w3.org/2000/svg" version="1" viewBox="0 0 24 24"><path d="M13 12l5-5-1-1-5 5-5-5-1 1 5 5-5 5 1 1 5-5 5 5 1-1z"/></svg>' +
            "</button>"
    },
    share: {
        url: function (instance, item) {
            return (
                (!instance.currentHash && !(item.type === "inline" || item.type === "html") ? item.origSrc || item.src : false) || window.location
            );
        },
        tpl: '<div class="fancybox-share">' +
            "<h1>{{SHARE}} !</h1>" +
            "<p>" +
            '<a class="fancybox-share__button fancybox-share__button--fb" href="https://www.facebook.com/sharer/sharer.php?u={{url}}">' +
            '<svg viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg"><path d="m287 456v-299c0-21 6-35 35-35h38v-63c-7-1-29-3-55-3-54 0-91 33-91 94v306m143-254h-205v72h196" /></svg>' +
            "<span>Facebook</span>" +
            "</a>" +
            '<a class="fancybox-share__button fancybox-share__button--tw" href="https://twitter.com/intent/tweet?url={{url}}&text={{descr}}">' +
            '<svg viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg"><path d="m456 133c-14 7-31 11-47 13 17-10 30-27 37-46-15 10-34 16-52 20-61-62-157-7-141 75-68-3-129-35-169-85-22 37-11 86 26 109-13 0-26-4-37-9 0 39 28 72 65 80-12 3-25 4-37 2 10 33 41 57 77 57-42 30-77 38-122 34 170 111 378-32 359-208 16-11 30-25 41-42z" /></svg>' +
            "<span>Twitter</span>" +
            "</a>" +
            '<a class="fancybox-share__button fancybox-share__button--pt" href="https://www.pinterest.com/pin/create/button/?url={{url}}&description={{descr}}&media={{media}}">' +
            '<svg viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg"><path d="m265 56c-109 0-164 78-164 144 0 39 15 74 47 87 5 2 10 0 12-5l4-19c2-6 1-8-3-13-9-11-15-25-15-45 0-58 43-110 113-110 62 0 96 38 96 88 0 67-30 122-73 122-24 0-42-19-36-44 6-29 20-60 20-81 0-19-10-35-31-35-25 0-44 26-44 60 0 21 7 36 7 36l-30 125c-8 37-1 83 0 87 0 3 4 4 5 2 2-3 32-39 42-75l16-64c8 16 31 29 56 29 74 0 124-67 124-157 0-69-58-132-146-132z" fill="#fff"/></svg>' +
            "<span>Pinterest</span>" +
            "</a>" +
            "</p>" +
            '<p><input class="fancybox-share__input" type="text" value="{{url_raw}}" /></p>' +
            "</div>"
    }
};

function addPhoto(img) {

    var $img = $(
        '<div class="grid-item"><a data-fancybox-pbooth="gallery" data-name="' + img + '" href="/data/images/' +
        img + '"><img src="/data/images/' + img + '"></a></div>'
    );

    $grid.append($img)
        .packery('appended', $img).packery();
    var instance = $.fancybox.getInstance();
    var $target = $('a', $img);
    if (instance) {
        instance.addContent($target);
    } else {
        $('html, body').animate({
            scrollTop: $target.offset().top
        }, 1000, function () {
            // Callback after animation
            // Must change focus!
            $target.focus();
            if ($target.is(":focus")) { // Checking if the target was focused
                return false;
            } else {
                $target.attr('tabindex', '-1'); // Adding tabindex for elements not focusable
                $target.focus(); // Set focus again
            };
        });
        var $gallery_items = $('.grid a:visible');
        $.fancybox.open($gallery_items, fancybox_defaults, $gallery_items.length - 1);
    }

}

function initGallery() {
    // Create template for the button
    $.fancybox.defaults.btnTpl.pbShare = '<a data-fancybox-pbShare data-morphing data-src="" href="javascript:;" class="btn pb-share"><i class="fas fa-qrcode mr-1"></i>QR code</a>';
    if (getUrlParameter('mode') == 'zoomed') {
        fancybox_defaults['afterLoad'] = function (instance, slide) {
            instance.scaleToActual();
        }
    }
    $().fancybox(fancybox_defaults);
}

var filterFns = {
    // show if number is greater than 50
    numberGreaterThan50: function () {
        // use $(this) to get item element
        var number = $(this).find('.number').text();
        return parseInt(number, 10) > 50;
    },
    // show if name ends with -ium
    ium: function () {
        var name = $(this).find('a').attr('href');
        return name.match(/1.jpg$/);
    }
};

function filterGallery() {
    filterValue = filterFns['ium'];
    $grid.isotope({
        filter: filterValue
    }).packery({ stagger: 0 });
    $grid.on( 'arrangeComplete', function( event, laidOutItems ) {
        //
    });
}

$(function () {

    $grid = $('.grid');
    $.ajax({
        type: 'GET',
        contentType: 'application/json',
        url: '/api/v1/images',
        dataType: 'json',
        success: function (result) {

            var $images = [];
            result.forEach(function (img) {
                $images.push(
                    $('<div class="grid-item"><a data-fancybox-pbooth="gallery" data-name="' + img + '" href="/data/images/' +
                        img + '"><img src="/data/thumbs/' + img + '"></a></div>')
                );
            });
            $grid.append($images);

            $grid.promise().done(function () {
                // Create reponsive grid
                $grid = $grid.packery({
                    itemSelector: '.grid-item',
                    columnWidth: '.grid-sizer',
                    //rowHeight: '.grid-sizer',
                    gutter: '.gutter-sizer',
                    percentPosition: true,
                    stagger: 30,
                    resize: false,
                })
                .isotope({
                    initLayout: false,
                    itemSelector: '.grid-item',
                    layoutMode: 'packery',
                    packery: {
                        columnWidth: '.grid-sizer',
                        //rowHeight: '.grid-sizer',
                        gutter: '.gutter-sizer'
                    },
                    percentPosition: true,
                });

                // layout Packery after each image loads
                $grid.imagesLoaded().progress(function () {
                    $grid.packery();
                    initGallery();
                });
            });

        },
        error: function (result) {
            console.log(result);
        }
    });

    socket = io('/gallery');

    socket.on('connect', function () {
        socket.emit('gallery_connect', {
            data: 'Gallery connected'
        });
    });

    socket.on('welcome', (data) => {
        console.log(data);
    });

    socket.on('newPic', (data) => {
        console.log('newPic', data);
        addPhoto(data['img']);
    });
});
