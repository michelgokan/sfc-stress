var crypto = require('crypto');
var fs = require('fs');


function checksum(str, algorithm, encoding) {
    return crypto
        .createHash(algorithm || 'md5')
        .update(str, 'utf8')
        .digest(encoding || 'hex')
}

function getRandomInt(max) {
    return Math.floor(Math.random() * Math.floor(max));
}

module.exports = {
    CPUIntensiveWorkload: function () {
        for ($i = 0; $i < 100; $i++){
           checksum(getRandomInt(999999999999).toString());
        }

        return "100 CHKSM OK!" 
    },
    memoryIntensiveWorkload: function () {
        $bigStr = "";

        for ($i = 0; $i < 1024 * 1024; $i++) {
            $bigStr = $bigStr + "a";
        }

        return "1";
    },
    diskIntensiveWorkload: function () {
        var file_suffix = getRandomInt(99999999);
        var file_name = "/tmp/test" + file_suffix;
        var stream = fs.createWriteStream(file_name);

        stream.once('open', function (fd) {
            for ($i = 0; $i < 1024 * 1024; $i++) {
                stream.write("0");
            }
            stream.end(function () {
                fs.unlinkSync(file_name);
            });
        });

        return "1";
    },
    networkIntensiveWorkload: function() {
        $bigStr = "";

        for ($i = 0; $i < 1024 * 1024; $i++) {
            $bigStr = $bigStr + "a";
        }

        return $bigStr;
    },
    combinedWorkload: function(){
        $a = this.CPUIntensiveWorkload();
        $b = this.memoryIntensiveWorkload();
        $c = this.diskIntensiveWorkload();
        $d = this.networkIntensiveWorkload();

        return $d;
    }
};
