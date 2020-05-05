/*
 *
 * M&M Photobooth hooks 
 * grep -qF photobooth.js /var/www/html/index.php || sed -i '/<\/body>/i \\t<script type="text\/javascript" src="resources\/js\/photobooth.js"><\/script>' /var/www/html/index.php
*/

(function (w){
    $.getScript("/static/socketio/socket.io.js", function(){

        socket = io();

        socket.on('connect', function() {
            socket.emit('photobooth_connect', {data: 'Manager connected'});
        });

        var fn_ref = photoBooth.thrill;
        photoBooth.thrill = function (args){
            socket.emit('photobooth_trigger', {action: args});
            fn_ref.apply(this, [args]);
        }

        console.log("Photobooth hooks loaded.");
     });
})(window || {});
