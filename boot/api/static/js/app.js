Dropzone.autoDiscover = false;
var backgroundGlider;
var frameGlider;
var ledpanel_default;
var socket;
var psocket;

const sleep = (milliseconds) => {
    return new Promise(resolve => setTimeout(resolve, milliseconds))
  }

function ping(url) {
    return new Promise((resolve, reject) => {
        var d = new Date();
        $.ajax({
            type: "GET",
            url: url,
            cache: false,
            timeout: 60000,
            success: function(html, status, req) {
                var d2 = new Date();
                var time = d2.getTime() - d.getTime();
                if (req.status == 200 && time < 18000) {
                    if (time > 10) {
                        // console.log(time + "ms.");
                    }
                    resolve(true);
                } else {
                    console.log("error! status: " + req.status);
                    resolve(false);
                }
            },
            error: function(req, status, error) {
                console.log("error! status: " + req.status + " error: " + error);
                resolve(false);
            }
        });
    });
}

const reconnect = async(url, tries, burst, wait, $progressbar) => {
    var status = false;
    var progress = 0;
    while (status == false && progress < 100) {
        var ms;
        if (progress == 0) {
            ms = wait;
        } else {
            ms = burst;
        }
        await sleep(wait);
        if (status == false) {
            ping(url).then(ping_result => {
                status = ping_result;
                $progressbar.css('width', progress + '%').attr("aria-valuenow", progress);
                progress = progress + (100 / tries);
                // console.log('ping', progress + '%', status);
            })
            .catch(error => {
                //
            });
        }
    }
    progress = 100;
    if (status == true) {
        $('.loadingoverlay_element').fadeOut( function() {
            $('.loadingoverlay_element').first().html('<i class="fas fa-check"></i>').css('color', 'green').fadeIn(  function() {
                $.LoadingOverlay("hide");
            });
        });
    } else {
        $('.loadingoverlay_element').fadeOut( function() {
            $('.loadingoverlay_element').first().html('<i class="fas fa-times"></i>').css('color', 'red').fadeIn(  function() {
                $('.loadingoverlay_element').first().delay(2000).html('<small>Please reconnect...<small>');
            });
        });
    }
}

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
        if (data['status'][0] == 0) {
            $('.loadingoverlay_element').fadeOut( function() {
                $('.loadingoverlay_element').first().html('<i class="fas fa-check"></i>').css('color', 'green').fadeIn(  function() {
                    $("#wifi-setup").LoadingOverlay("hide");
                });
            });
        } else {
            $('.loadingoverlay_element').fadeOut( function() {
                $('.loadingoverlay_element').first().html('<i class="fas fa-times"></i>').css('color', 'red').fadeIn(  function() {
                    $("#wifi-setup").LoadingOverlay("hide");
                });
            });
        }
    });
}

async function update_ap(){
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
        // might not return due to hostapd restart
    });
    reconnect('/', 10, 1000, 1000, $('#ap-update-info')).then(() => {
        if ($('#hideAP').is(":checked")) {
            $('#hotspot-visibility')
             .addClass('fa-eye-slash')
             .removeClass('fa-eye');
        } else {
            $('#hotspot-visibility')
             .addClass('fa-eye')
             .removeClass('fa-eye-slash');
        }
        if ($('#ap-password').val() == '') {
            $('#hotspot-security')
             .addClass('fa-lock-open')
             .removeClass('fa-lock');
        } else {
            $('#hotspot-security')
             .addClass('fa-lock')
             .removeClass('fa-lock-open');
        }
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

function parse_trigger_actions(){
    trigger_parsed = {
        'actions': []
    }
    
    $('#accordion div.trigger-card').each(function(trigger_idx, trigger_card) {			
        trigger = $(trigger_card).data('trigger');
        index = trigger_idx + 1;
    
        ledpanel_parsed = [];
        $actions_ledpanel = $('#actions-ledpanel-' + index)
        $actions_ledpanel.find('.card').each(function(action_idx, action_card) {
            action = $(action_card).data('action');
            action_parsed = {
                'name': action.toString(),
                'slots': []
            }
            $(action_card).find('.slot').each(function(slot_idx, slot) {
                configs = {}
                $(slot).find('input, select').each(function(form_idx, form_component) {
                    $component = $(form_component);
                    node = $component.prop('nodeName');
                    field = $component.data('field');
                    if (node == 'INPUT') {
                        if (field == 'brightness' && ($component.val().toString().trim() === "" || $component.val().toString() == null)) {
                            $component.val('1.0');
                        } else {
                            configs[field] = $component.val().toString();
                        }
                    } else if (node == 'SELECT') {
                        configs[field] = $('option:selected', $component).val().toString();
                    }
                });
                action_parsed.slots.push(configs);
            });
    
            ledpanel_parsed.push(action_parsed);
        });
        
        gpio_parsed = [];
        $actions_gpio = $('#actions-gpio-' + index)
        $actions_gpio.find('.card').each(function(action_idx, action_card) {
            action = $(action_card).data('action');
            action_parsed = {
                'name': action.toString(),
                'slots': []
            }
            $(action_card).find('.slot').each(function(slot_idx, slot) {
                configs = {}
                $(slot).find('input, select').each(function(form_idx, form_component) {
                    $component = $(form_component);
                    node = $component.prop('nodeName');
                    field = $component.data('field');
                    if (node == 'INPUT') {
                        configs[field] = $component.val().toString();;
                    } else if (node == 'SELECT') {
                        configs[field] = $('option:selected', $component).val().toString();;
                    }
                });
                action_parsed.slots.push(configs);
            });
    
            gpio_parsed.push(action_parsed);
        });

        remote_parsed = [];
        $actions_remote = $('#actions-remote-' + index)
        $actions_remote.find('.card').each(function(action_idx, action_card) {
            action = $(action_card).data('action');
            action_parsed = {
                'name': action.toString(),
                'slots': []
            }
            $(action_card).find('.slot').each(function(slot_idx, slot) {
                configs = {}
                $(slot).find('input, select').each(function(form_idx, form_component) {
                    $component = $(form_component);
                    node = $component.prop('nodeName');
                    field = $component.data('field');
                    if (node == 'INPUT') {
                        configs[field] = $component.val().toString();;
                    } else if (node == 'SELECT') {
                        configs[field] = $('option:selected', $component).val().toString();;
                    }
                });
                action_parsed.slots.push(configs);
            });
    
            remote_parsed.push(action_parsed);
        });
    
        trigger_parsed.actions.push({
            'trigger': trigger,
            'ledpanel': ledpanel_parsed,
            'gpio': gpio_parsed,
            'remote': remote_parsed
        })
    });
    return trigger_parsed
}

function colorChangeCallback(color, action) {
    socket.emit('setup_ledpanel_realtime_color_change', {action: action, color: color.rgbString, alpha: color.alpha});
}

function add_color_picker($target){
    $target.click(function() {
        var action = $('option:selected', $(this).data('action')).text();
        var trigger = $(this).data('trigger');
        var customElement = $('<div>', {
            "id" : "color-picker",
            "class" : "color-picker-area",
            "css"   : {
                "text-align"    : "center",
                "padding"       : "10px"
            }
        });
        var colorpicker_close = $('<div>').append($('<i>', {
            "class" : "color-picker-close fas fa-times-circle fa-2x",
            "css"   : {
                "position" : "relative",
                "left"    : "100px"
            }
        }));
        $.LoadingOverlay("show", {
            image       : "",
            custom      : customElement,
            fade : [400, 200]
        });
        customElement.prepend(colorpicker_close);

        var color_picker = show_color_picker("#color-picker", $target);
        color_picker.on("color:change", function(color){
            colorChangeCallback(color, action);
        });
        colorpicker_close.click(function() {
            var color = color_picker.color;
            $target.children().first().css("color", color.rgbString);
            $target.children().first().next().text((Math.round(color.alpha * 100) / 100).toFixed(2));
            $target.next().val(color.rgbString);
            $target.next().next().val(color.alpha);
            if (trigger == "default") {
                set_ledpanel_defaults();
            } else {
                socket.emit('setup_ledpanel_realtime_color_change', ledpanel_default);
            }
            $.LoadingOverlay("hide");
        });
    });
}

function set_ledpanel_defaults() {
    var _action = $('.theme-defaults .slot select[data-field="action"]').val();
    var _color = $('.theme-defaults .slot input[data-field="color"]').val()
    var _alpha = $('.theme-defaults .slot input[data-field="brightness"]').val()
    ledpanel_default = {action: _action, color: _color, alpha: _alpha};
}

function show_color_picker(target, btn){    
    var colorPicker = new iro.ColorPicker(target, {
        width: 200,
        color: btn.next().val(),
        layout: [
            { 
                component: iro.ui.Wheel,
                options: {
                }
            },
            { 
                component: iro.ui.Slider,
                options: {
                    sliderType: 'alpha'
                }
            },
        ]
    });
    colorPicker.color.setChannel('rgba', 'a', btn.next().next().val());
    return colorPicker
}

function load_modules(){
    $("#modules-list").LoadingOverlay("show", {
        image       : "",
        fontawesome : "fa fa-sync-alt fa-spin",
        fontawesomeColor: "Dodgerblue",
        fade : [400, 200]
    });
    $("#modules-list").load( "/setup/modules/list", function() {
        $("#modules-list").LoadingOverlay("hide");
    });
}

function load_vnstat(){
    $("#stats-wrapper").LoadingOverlay("show", {
        image       : "",
        fontawesome : "fa fa-sync-alt fa-spin",
        fontawesomeColor: "Dodgerblue",
        fade : [400, 200]
    });
    $("#stats-wrapper").load( "/vnstat/?var1=1 #main", function() {
        $("#stats-wrapper").LoadingOverlay("hide");
    });
}

function update_remotes_selector(target){
    target.click(function() {
        var $that = $(this);
        var selected = $('option:selected', $that).text();
        var uids = $('#modules-list').find('.remote-instance').map(function() {
                return $( this ).data('uid');
            }).get();
        $that.empty();
        var attr = '';
        uids.forEach(function(uid) { 
            if (uid == selected) {
                attr = 'selected'
            }
            $that.append(
                $("<option " + attr + "></option>")
                .attr("value", uid)
                .text(uid)
            ); 
        });
    });
}

$(function() {

    set_ledpanel_defaults();
    load_wifis();
    load_backgrounds();
    load_frames();
    load_modules();
    load_vnstat();

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
        if (/\s/g.test(password) || (password.length >0 && password.length < 8)) {
            $('#ap-password-error').fadeIn();
            return
        }
        update_ap();
    });

    $('#ap-password-clear').click(function() {
        $('#ap-password').val('');
    });

    $('.slot-delete').click(function() {
        $($(this).data('target')).remove();
    });

    $('.slot-add').click(function() {
        target = $(this).data('target');
        prefix = $(this).data('prefix');
        index = $(this).data('index');
        added = $(this).data('added');
        $target = $(target + "-" + prefix + "-" + index);
        index_next = parseInt( index, 10 ) + 1 + added;
        
        $clone = $target.clone();
        $clone.toggleClass('slot slot-template');
        clone_id_new = $clone.prop('id').replace(prefix + '-' + index, prefix + '-' + index_next)
        $clone.prop('id', clone_id_new);
        $('*[id$="' + prefix + '-' + index + '"]' , $clone).each(function() {
            id_new = $(this).prop('id').replace(prefix + '-' + index, prefix + '-' + index_next);
            $(this).prop('id', id_new);
        });
        $('.slot-delete', $clone).data('target', '#' + clone_id_new).click(function() {
            $($(this).data('target')).remove();
        });
        $color_picker_btn = $('.color-picker-btn', $clone);
        $color_picker_btn.data('target', '#' + clone_id_new);
        add_color_picker($color_picker_btn);
        $color_picker_btn.next().val("rgb(255,255,255)")
        $color_picker_btn.children().first().css("color", "rgb(255,255,255)");
        $color_picker_btn.next().next().val($color_picker_btn.children().first().next().text());
        update_remotes_selector($('.remote-id-select', $clone));
        $clone.insertBefore($target).fadeIn();
        $(this).data('added', added + 1);
    });
    
    $('.trigger-action-submit').click(function() {
        $('.collapse.show').LoadingOverlay("show", {
            image       : "",
            fontawesome : "fa fa-sync-alt fa-spin",
            fontawesomeColor: "Dodgerblue",
            fade : [400, 200]
        });
        $.ajax({
            type: 'POST',
            contentType: 'application/json',
            url: '/setup/trigger/actions/update',
            dataType : 'json',
            data : JSON.stringify(parse_trigger_actions()),
            success : function(result) {
                $('.loadingoverlay_element').fadeOut( function() {
                    $('.loadingoverlay_element').first().html('<i class="fas fa-check"></i>').css('color', 'green').fadeIn(  function() {
                        $('.collapse.show').LoadingOverlay("hide");
                    });
                });
                psocket.emit('trigger', {action: 'default', args: 'fade'});
            },error : function(result){
                $('.loadingoverlay_element').fadeOut( function() {
                    $('.loadingoverlay_element').first().html('<i class="fas fa-times"></i>').css('color', 'red').fadeIn(  function() {
                        $('.collapse.show').LoadingOverlay("hide");
                    });
                });
            }
        });
    });

    $('.color-picker-btn').each(function() {
        add_color_picker($(this));
    });

    $('.optargs-toggle').click(function() {
        $(this).closest('div[id|="ledpanel-slot"]').find('.optargs').slideToggle();
    });

    update_remotes_selector($('.remote-id-select'));

    socket = io();
    psocket = io('/photobooth');
    
    socket.on('connect', function() {
        socket.emit('manager_connect', {data: socket.id});
    });

});
