/*
 *
 * M&M Photobooth hooks 
 *
*/

(function (w){
    $.getScript("/static/socketio/socket.io.js", function(){

        socket = io('/photobooth');

        socket.on('connect', function() {
            socket.emit('photobooth_connect', {data: 'Photobooth connected'});
        });

        var thrill_ref = photoBooth.thrill;
        photoBooth.thrill = function (arg1){
            socket.emit('trigger', {action: 'thrill', args: arg1});
            thrill_ref.apply(this, [arg1]);
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
        
        var processPic_ref = photoBooth.processPic;
        photoBooth.processPic = function (arg1, arg2){
            socket.emit('trigger', {action: 'processPic', args: arg1});
            processPic_ref.apply(this, [arg1, arg2]);
        }
        var startCountdown_ref = photoBooth.startCountdown;
        photoBooth.startCountdown = function (start, element, cb){
            //startCountdown_ref.apply(this, [start, element, cb]);
            let count = 0;
            let current = start;
    
            function timerFunction() {
                socket.emit('trigger', {action: 'countdown', args: current});
                
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

        console.log("Photobooth hooks loaded.");
     });
})(window || {});
