Dropzone.autoDiscover = false;
var backgroundGlider;
var frameGlider;

function load_images(callback){
    [].forEach.call(this.querySelectorAll('img'),function(img){
        var _img = new Image,  _src = img.getAttribute('data-src');
        _img.onload = function(){
            img.src = _src;
            img.classList.add('loaded');
            callback && callback(img);
        }
        if(img.src !== _src)	_img.src = _src;
    });
}

function load_wifis(){
    $("#wifi-list").LoadingOverlay("show", {
        image       : "",
        fontawesome : "fa fa-sync-alt fa-spin",
        fontawesomeColor: "Dodgerblue",
        fade : [400, 200]
    });
    $("#wifi-list").load( "/setup/wifi/list", function() {
        $("#wifi-list").LoadingOverlay("hide");
        $("#wifi-count").text($('#wifi-list > option').length - 1);
    });
}

function connect_wifi(){
    $("#wifi-setup").LoadingOverlay("show", {
        image       : "",
        fontawesome : "fa fa-sync-alt fa-spin",
        fontawesomeColor: "Dodgerblue",
        fade : [400, 200]
    });
    data = {
        'ssid': $('#wifi-list option:selected').text(),
        'password': $('#wifi-password').val()
    }
    $.post("/setup/wifi/connect", data, function( data ) {
        $('#wifi-password').val('')
        $("#wifi-setup").LoadingOverlay("hide");
    });
}

function update_ap(){
    $.LoadingOverlay("show", {
        image       : "",
        fontawesome : "fa fa-sync-alt fa-spin",
        fontawesomeColor: "Dodgerblue",
        fade : [400, 200]
    });
    data = {
        'ssid': $('#ap-ssid').val(),
        'password': $('#ap-password').val(),
        'hidden': ($('#hideAP').is(":checked") ? 1 : 0)
    }
    $.post("/setup/wifi/ap/settings", data, function( data ){
        $('#ap-password').val('');
        $.LoadingOverlay("show", {
            image  : '',
            custom : '<div><h1>Restarting...</h1><small>Please reconnect to the photobooth hotspot in about 30 seconds.</small></div>',
            size : 30,
            minSize : 0,
            maxSize : 0 
        });
    });
}

function load_backgrounds(){
    $.getJSON( "/manager/api/background/get", function( data ) {
        $.each( data.data, function( i, item ) {
            $("<div/>")
            .append($( "<img>" ).attr( "data-src", "/manager/files/backgrounds/" + item ).attr( "data-fname", item ))
            .appendTo( ".background" );
        });

        document.querySelector('.background').addEventListener('glider-slide-visible', function(event){
        var glider = Glider(this);
            // console.log('Slide Visible %s', event.detail.slide)
        });
        document.querySelector('.background').addEventListener('glider-slide-hidden', function(event){
            // console.log('Slide Hidden %s', event.detail.slide)
        });
        document.querySelector('.background').addEventListener('glider-refresh', function(event){
            // console.log('Refresh')
        });
        document.querySelector('.background').addEventListener('glider-loaded', function(event){
            // console.log('Loaded')
        });

        backgroundGlider = new Glider(document.querySelector('.background'), {
            slidesToShow: 1, //'auto',
            slidesToScroll: 1,
            itemWidth: 150,
            draggable: true,
            scrollLock: false,
            dots: '#dots_background',
            rewind: true,
            arrows: {
                prev: '.background-prev',
                next: '.background-next'
            },
            responsive: [
                {
                    breakpoint: 800,
                    settings: {
                        slidesToScroll: 1,
                        slidesToShow: 1,
                        itemWidth: 300
                    }
                },
                {
                    breakpoint: 700,
                    settings: {
                        slidesToScroll: 1,
                        slidesToShow: 1,
                        dots: false,
                        arrows: false,
                    }
                },
                {
                    breakpoint: 600,
                    settings: {
                        slidesToScroll: 1,
                        slidesToShow: 1
                    }
                },
                {
                    breakpoint: 500,
                    settings: {
                        slidesToScroll: 1,
                        slidesToShow: 1,
                        dots: false,
                        arrows: false,
                        scrollLock: true
                    }
                }
            ]
        });
    });

    document.querySelector('.background').addEventListener('glider-slide-visible', function(event){
        var imgs_to_anticipate = 3;
        var glider = Glider(this);
        $( this ).find(".glider-slide").each(function() {
            $( this ).addClass("justify-content-center align-self-center");
        });
        for (var i = 0; i <= imgs_to_anticipate; ++i){
            var index = Math.min(event.detail.slide + i, glider.slides.length - 1),
            glider = glider;
                load_images.call(glider.slides[index],function(){
            glider.refresh(true);
            })
        }
    });
}

function load_frames(){
    $.getJSON( "/manager/api/frame/get", function( data ) {
        $.each( data.data, function( i, item ) {
            $("<div/>")
            .append($( "<img>" ).attr( "data-src", "/manager/files/frames/" + item ).attr( "data-fname", item ))
            .appendTo( ".frame" );
        });

        document.querySelector('.frame').addEventListener('glider-slide-visible', function(event){
        var glider = Glider(this);
            // console.log('Slide Visible %s', event.detail.slide)
        });
        document.querySelector('.frame').addEventListener('glider-slide-hidden', function(event){
            // console.log('Slide Hidden %s', event.detail.slide)
        });
        document.querySelector('.frame').addEventListener('glider-refresh', function(event){
            // console.log('Refresh')
        });
        document.querySelector('.frame').addEventListener('glider-loaded', function(event){
            // console.log('Loaded')
        });

        frameGlider = new Glider(document.querySelector('.frame'), {
            slidesToShow: 1, //'auto',
            slidesToScroll: 1,
            itemWidth: 150,
            draggable: true,
            scrollLock: false,
            dots: '#dots_frame',
            rewind: true,
            arrows: {
                prev: '.frame-prev',
                next: '.frame-next'
            },
            responsive: [
                {
                    breakpoint: 800,
                    settings: {
                        slidesToScroll: 1,
                        slidesToShow: 1,
                        itemWidth: 300
                    }
                },
                {
                    breakpoint: 700,
                    settings: {
                        slidesToScroll: 1,
                        slidesToShow: 1,
                        dots: false,
                        arrows: false,
                    }
                },
                {
                    breakpoint: 600,
                    settings: {
                        slidesToScroll: 1,
                        slidesToShow: 1
                    }
                },
                {
                    breakpoint: 500,
                    settings: {
                        slidesToScroll: 1,
                        slidesToShow: 1,
                        dots: false,
                        arrows: false,
                        scrollLock: true
                    }
                }
            ]
        });
    });

    document.querySelector('.frame').addEventListener('glider-slide-visible', function(event){
        var imgs_to_anticipate = 3;
        var glider = Glider(this);
        $( this ).find(".glider-slide").each(function() {
            $( this ).addClass("justify-content-center align-self-center");
        });
        for (var i = 0; i <= imgs_to_anticipate; ++i){
            var index = Math.min(event.detail.slide + i, glider.slides.length - 1),
            glider = glider;
            load_images.call(glider.slides[index],function(){
                glider.refresh(true);
            })
        }
    });
}

$(function() {

    load_wifis();
    load_backgrounds();
    load_frames();

    var backgroundDrop = $("div#background-card").dropzone({
        url: "/manager/api/background/store",
        createImageThumbnails: false,
        previewsContainer: ".dropzonejs-preview",
        clickable: "#background-uploadbutton",
        init: function() {
            this.on("dragenter", function(file) {
                $('#background-card').addClass("dropzone-drag-hover");
            }),
            this.on("dragend", function(file) {
                $('#background-card').removeClass("dropzone-drag-hover");
            }),
            this.on("dragleave", function(file) {
                $('#frame-card').removeClass("dropzone-drag-hover");
            }),
            this.on("drop", function(file) {
                $('#background-card').removeClass("dropzone-drag-hover");
            }),
            this.on("success", function(file, response) {
                if (response.data == "exists") {
                    $('#background-upload .alert-msg').text("Background image alread exists");
                } else if (response.data == "no-file") {
                    $('#background-upload .alert-msg').text("Error while uploading");
                } else {
                    $('#background-upload .alert-msg').text("New background image added");
                    var ele = document.getElementById('glider-add').cloneNode(true);
                    $(ele).attr('id','').attr( "src", "/manager/files/backgrounds/" + response.data).attr( "data-fname", response.data ).appendTo(".background-glider-tmp");
                    backgroundGlider.addItem(ele);
                    
                    backgroundGlider.scrollItem(backgroundGlider.slides.length-1);
                }
                $('#background-upload').fadeIn().delay("1000").fadeOut();
            })
        },
        accept: function(file, done) {
            if ((/\.(gif|jpe?g|tiff|png)$/i).test(file.name)) {
                done();
            }
            else {
                $('#background-upload .alert-msg').text("Images only");
                $('#background-upload').fadeIn().delay("1000").fadeOut();
                done("Images only.");
            }
        }
    });

    $("div#frame-card").dropzone({
        url: "/manager/api/frame/store",
        createImageThumbnails: false,
        previewsContainer: ".dropzonejs-preview",
        clickable: "#frame-uploadbutton",
        init: function() {
            this.on("dragenter", function(file) {
                $('#frame-card').addClass("dropzone-drag-hover");
            }),
            this.on("dragend", function(file) {
                $('#frame-card').removeClass("dropzone-drag-hover");
            }),
            this.on("dragleave", function(file) {
                $('#background-card').removeClass("dropzone-drag-hover");
            }),
            this.on("drop", function(file) {
                $('#frame-card').removeClass("dropzone-drag-hover");
            }),
            this.on("success", function(file, response) {
                if (response.data == "exists") {
                    $('#frame-upload .alert-msg').text("frame alread exists");
                } else if (response.data == "no-file") {
                    $('#frame-upload .alert-msg').text("Error while uploading");
                } else {
                    $('#frame-upload .alert-msg').text("New frame added");
                    var ele = document.getElementById('glider-add').cloneNode(true);
                    $(ele).attr('id','').attr( "src", "/manager/files/frames/" + response.data).attr( "data-fname", response.data ).appendTo(".frame-glider-tmp");
                    frameGlider.addItem(ele);
                    frameGlider.scrollItem(frameGlider.slides.length-1);
                }
                $('#frame-upload').fadeIn().delay("1000").fadeOut();
            })
        },
        accept: function(file, done) {
            if ((/\.(png)$/i).test(file.name)) {
                done();
            }
            else {
                $('#frame-upload .alert-msg').text("PNGs only");
                $('#frame-upload').fadeIn().delay("1000").fadeOut();
                done("PNGs only.");
            }
        }
    });

    $( "#background-selectbutton" ).click(function() {
        $("#background-card").LoadingOverlay("show", {
            image       : "",
            fontawesome : "fa fa-sync-alt fa-spin",
            fontawesomeColor: "Dodgerblue",
            fade : [400, 200]
        });
        $.getJSON( "/manager/api/background/select", {
            fname: backgroundGlider.slides[backgroundGlider.slide].dataset.fname ? backgroundGlider.slides[backgroundGlider.slide].dataset.fname : $(backgroundGlider.slides[backgroundGlider.slide]).find('[data-fname]').attr("data-fname")
        }, function( data ) {
            $('.loadingoverlay_element').fadeOut( function() {
                $('.loadingoverlay_element').first().html('<i class="fas fa-check"></i>').css('color', 'green').fadeIn(  function() {
                    $("#background-card").LoadingOverlay("hide");
                });
            });
        });
    });

    $( "#background-deletebutton" ).click(function() {
        $("#background-card").LoadingOverlay("show", {
            image       : "",
            fontawesome : "fa fa-sync-alt fa-spin",
            fontawesomeColor: "Dodgerblue",
            fade : [400, 200]
        });
        $.getJSON( "/manager/api/background/delete", {
            fname: backgroundGlider.slides[backgroundGlider.slide].dataset.fname ? backgroundGlider.slides[backgroundGlider.slide].dataset.fname : $(backgroundGlider.slides[backgroundGlider.slide]).find('[data-fname]').attr("data-fname")
        }, function( data ) {
            backgroundGlider.removeItem(backgroundGlider.slide);
            $('.loadingoverlay_element').fadeOut( function() {
                $('.loadingoverlay_element').first().html('<i class="fas fa-check"></i>').css('color', 'green').fadeIn(  function() {
                    $("#background-card").LoadingOverlay("hide");
                });
            });
        });
    });

    $( "#frame-selectbutton" ).click(function() {
        $("#frame-card").LoadingOverlay("show", {
            image       : "",
            fontawesome : "fa fa-sync-alt fa-spin",
            fontawesomeColor: "Dodgerblue",
            fade : [400, 200]
        });
        $.getJSON( "/manager/api/frame/select", {
            fname: frameGlider.slides[frameGlider.slide].dataset.fname ? frameGlider.slides[frameGlider.slide].dataset.fname : $(frameGlider.slides[frameGlider.slide]).find('[data-fname]').attr("data-fname")
        }, function( data ) {
            $('.loadingoverlay_element').fadeOut( function() {
                $('.loadingoverlay_element').first().html('<i class="fas fa-check"></i>').css('color', 'green').fadeIn(  function() {
                    $("#frame-card").LoadingOverlay("hide");
                });
            });
        });
    });

    $( "#frame-deletebutton" ).click(function() {
        $("#frame-card").LoadingOverlay("show", {
            image       : "",
            fontawesome : "fa fa-sync-alt fa-spin",
            fontawesomeColor: "Dodgerblue",
            fade : [400, 200]
        });
        $.getJSON( "/manager/api/frame/delete", {
            fname: frameGlider.slides[frameGlider.slide].dataset.fname ? frameGlider.slides[frameGlider.slide].dataset.fname : $(frameGlider.slides[frameGlider.slide]).find('[data-fname]').attr("data-fname")
        }, function( data ) {
            frameGlider.removeItem(frameGlider.slide);
            $('.loadingoverlay_element').fadeOut( function() {
                $('.loadingoverlay_element').first().html('<i class="fas fa-check"></i>').css('color', 'green').fadeIn(  function() {
                    $("#frame-card").LoadingOverlay("hide");
                });
            });
        });
    });

    $('#hideInet-toggle').click(function() {
        ap_passthrough_url = "/setup/wifi/ap/passthrough/" + ($('#hideInet').is(":checked") ? 0 : 1)
        $.get(ap_passthrough_url, function(myData , status){
            //
        });
    });

    $('#wifi-scan').click(function() {
        load_wifis();
    });

    $('#wifi-connect').click(function() {
        password = $('#wifi-password').val()
        $('#wifi-password-error').hide();
        if (/\s/g.test(password) || password.length < 8) {
            $('#wifi-password-error').fadeIn();
            return
        }
        connect_wifi();
    });

    $('#settingsAP-update').click(function() {
        password = $('#ap-password').val()
        $('#ap-password-error').hide();
        if (/\s/g.test(password) || password.length < 8) {
            $('#ap-password-error').fadeIn();
            return
        }
        update_ap();
    });

    $('#ap-password-clear').click(function() {
        $('#ap-password').val('');
    });
    

});
