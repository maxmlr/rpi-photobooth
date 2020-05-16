/*
 *
 * M&M Photobooth hooks 
 *
*/

(function (w){
    $.when(
        $.getScript("/static/socketio/socket.io.js"),
        $.getScript("/static/fancybox/jquery.fancybox.min.js"),
        $.getScript("/static/js/morphing.js"),
        // $.Deferred(function( deferred ){
        //     $( deferred.resolve );
        // })
    ).done(function(){
        $('<link/>', {
            rel: 'stylesheet',
            type: 'text/css',
            href: '/static/css/morphing.css'
         }).appendTo('head');
         $('<link/>', {
            rel: 'stylesheet',
            type: 'text/css',
            href: '/static/css/photobooth.css'
         }).appendTo('head');

        var socket;

        var thrill_ref = photoBooth.thrill;
        photoBooth.thrill = function (arg1){
            socket.emit('trigger', {action: 'thrill', args: arg1});
            thrill_ref.apply(this, [arg1]);
        }

        var startCountdown_ref = photoBooth.startCountdown;
        photoBooth.startCountdown = function (start, element, cb){
            //startCountdown_ref.apply(this, [start, element, cb]);
            let count = 0;
            let current = start;
    
            function timerFunction() {
                socket.emit('trigger', {action: 'startCountdown', args: current});
                
                element.text(current);
                current--;
    
                element.removeClass('tick');
    
                if (count < start) {
                    window.setTimeout(() => element.addClass('tick'), 50);
                    window.setTimeout(timerFunction, 1000);
                } else {
                    cb();
                }
                count++;
            }
            timerFunction();
        }

        var cheese_ref = photoBooth.cheese;
        photoBooth.cheese = function (arg1){
            socket.emit('trigger', {action: 'cheese', args: arg1});
            cheese_ref.apply(this, [arg1]);
        }

        var takePic_ref = photoBooth.takePic;
        photoBooth.takePic = function (arg1){
            socket.emit('trigger', {action: 'takePic', args: arg1});
            takePic_ref.apply(this, [arg1]);
        }
        
        var renderPic_ref = photoBooth.renderPic;
        photoBooth.renderPic = function (arg1, arg2){
            socket.emit('trigger', {action: 'renderPic', args: arg1});
            renderPic_ref.apply(this, [arg1, arg2]);
        }

        var errorPic_ref = photoBooth.errorPic;
        photoBooth.errorPic = function (arg1){
            socket.emit('trigger', {action: 'errorPic', args: arg1});
            errorPic_ref.apply(this, [arg1]);
        }

        // $('.gallery-button').prop("onclick", null).off("click").click((event) => {
        //     event.preventDefault();
        //     photoBooth.closeNav();
        // })
        // .data('src', '/gallery')
        // .attr('href', 'javascript:;')
        // .attr('data-fancybox-gallery', '')
        // .removeClass('gallery-button')
        // .addClass('mbtn gallery-button-morphing')
        // .attr('data-morphing', '').fancyMorph({
        //     hash: 'morphing'
        // });

        socket = io('/photobooth');

        socket.on('connect', function() {
            socket.emit('photobooth_connect', {data: socket.id});
            socket.emit('trigger', {action: 'default', args: 'fade'});
        });

        console.log("Photobooth hooks loaded.");
     });
})(window || {});
