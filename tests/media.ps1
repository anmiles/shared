Import-Module $env:MODULES_ROOT\media.ps1 -Force

Function Test {
    Param (
        [Parameter(Mandatory = $true)][string]$name
    )

    $result = NormalizeMediaFilename $name

    if ($result.Date) {
        $date = $result.Date.ToString("yyyy.MM.dd_HH.mm.ss")
    } else {
        $date = $null
    }

    return @($result.Name, $date)
}

@(
    @{Input = "_DSC0123.JPG"; Expected = "_DSC0123.jpg | "},
    @{Input = ".dropsync"; Expected = ".dropsync | "},
    @{Input = "00001.mts"; Expected = "00001.mts | "},
    @{Input = "01 - Название снимка (пояснение).wmv"; Expected = "01 - Название снимка (пояснение).wmv | "},
    @{Input = "01.png"; Expected = "01.png | "},
    @{Input = "0123abcd-0123-0123-0123-012345abcdef.jfif"; Expected = "0123abcd-0123-0123-0123-012345abcdef.jfif | "},
    @{Input = "123ABCabc.jpg"; Expected = "123ABCabc.jpg | "},
    @{Input = "1.jpg"; Expected = "1.jpg | "},
    @{Input = "1.colorized.jpg"; Expected = "1.colorized.jpg | "},
    @{Input = "1 кадр.jpg"; Expected = "1 кадр.jpg | "},
    @{Input = "123-DSC01234.jpg"; Expected = "123-DSC01234.jpg | "},
    @{Input = "123456_001.jpg"; Expected = "123456_001.jpg | "},
    @{Input = "123456DSC_01234.jpg"; Expected = "123456DSC_01234.jpg | "},
    @{Input = "0aBc-123DeF.jpg"; Expected = "0aBc-123DeF.jpg | "},
    @{Input = "0aBc_123DeF.jpg"; Expected = "0aBc_123DeF.jpg | "},
    @{Input = "DSC_0123.JPG"; Expected = "DSC_0123.jpg | "},
    @{Input = "DSC_0123 (1).jpg"; Expected = "DSC_0123 (1).jpg | "},
    @{Input = "FACE_RC_1234000000000.jpg"; Expected = "FACE_RC_1234000000000.jpg | "},
    @{Input = "M2U01234.mpg"; Expected = "M2U01234.mpg | "},
    @{Input = "IMG_1234.jpg"; Expected = "IMG_1234.jpg | "},
    @{Input = "IMG_20121226.jpg"; Expected = "IMG_20121226.jpg | "},
    @{Input = "msg100000000-100000.jpg"; Expected = "msg100000000-100000.jpg | "},
    @{Input = "SCAN_20121226_0740-0.jpg"; Expected = "SCAN_20121226_0740-0.jpg | "},
    @{Input = "VID_100000000_100000_123.mp4"; Expected = "VID_100000000_100000_123.mp4 | "},
    @{Input = "video_2012-12-26_07-40-00.mp4"; Expected = "video_2012-12-26_07-40-00.mp4 | "},
    @{Input = "Название события 2012.mp4"; Expected = "Название события 2012.mp4 | "},
    @{Input = "название события_2012.jpg"; Expected = "название события_2012.jpg | "},
    @{Input = "Событие 01.01.2012.mp4"; Expected = "Событие 01.01.2012.mp4 | "},
    @{Input = "1356507600000.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012_0001.colorized.jpg"; Expected = "2012_0001.colorized.jpg | 2012.01.01_00.00.01"},
    @{Input = "2012_0002.jpg"; Expected = "2012_0002.jpg | 2012.01.01_00.00.02"},
    @{Input = "2012.03_0003.colorized.jpg"; Expected = "2012.03_0003.colorized.jpg | 2012.03.01_00.00.03"}
    @{Input = "2012.04_0004.jpg"; Expected = "2012.04_0004.jpg | 2012.04.01_00.00.04"},
    @{Input = "2012.05 Event.jpg"; Expected = "2012.05 Event.jpg | 2012.05.01_00.00.00"},
    @{Input = "2012.06.jpg"; Expected = "2012.06.jpg | 2012.06.01_00.00.00"},
    @{Input = "2012.12.26.jpg"; Expected = "2012.12.26.jpg | 2012.12.26_00.00.00"},
    @{Input = "2012.12.26 - Событие - Часть 1.mp4"; Expected = "2012.12.26 - Событие - Часть 1.mp4 | 2012.12.26_00.00.00"},
    @{Input = "2012.12.26_0001.jpg"; Expected = "2012.12.26_0001.jpg | 2012.12.26_00.00.01"},
    @{Input = "2012.12.26_0001 - !123++.jpg"; Expected = "2012.12.26_0001 - !123++.jpg | 2012.12.26_00.00.01"},
    @{Input = "2012.12.26_0002 - edited.jpg"; Expected = "2012.12.26_0002 - edited.jpg | 2012.12.26_00.00.02"},
    @{Input = "2012.12.26_0003 - new version - S0123456.jpg"; Expected = "2012.12.26_0003 - new version - S0123456.jpg | 2012.12.26_00.00.03"},
    @{Input = "2012.12.26_1234.jpg"; Expected = "2012.12.26_1234.jpg | 2012.12.26_00.20.34"},
    @{Input = "2012.12.26_01234.jpg"; Expected = "2012.12.26_01234.jpg | 2012.12.26_00.00.00"},
    @{Input = "2012.12.26 event Location.mp4"; Expected = "2012.12.26 event Location.mp4 | 2012.12.26_00.00.00"},
    @{Input = "2012.12.26_0001 Location name.jpg"; Expected = "2012.12.26_0001 Location name.jpg | 2012.12.26_00.00.01"},
    @{Input = "2012.12.26_all.mp4"; Expected = "2012.12.26_all.mp4 | 2012.12.26_00.00.00"},
    @{Input = "2012.12.26_001.jpg"; Expected = "2012.12.26_001.jpg | 2012.12.26_00.00.00"},
    @{Input = "2012.12.26_1080_4m.mp4"; Expected = "2012.12.26_1080_4m.mp4 | 2012.12.26_00.18.00"},
    @{Input = "2012.12.26_07.40.00.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012-12-26_07.40.00 (1).mp4"; Expected = "2012.12.26_07.40.00.mp4 | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00_1.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00_1+.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00+.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00++.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00-.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07400099.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_27400099.jpg"; Expected = "2012.12.26_27400099.jpg | "},
    @{Input = "2012.12.26_07.40.00 (1).mp4"; Expected = "2012.12.26_07.40.00.mp4 | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00 (1.5).mp4"; Expected = "2012.12.26_07.40.00.mp4 | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00_01.mp4"; Expected = "2012.12.26_07.40.00.mp4 | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00_01+.mp4"; Expected = "2012.12.26_07.40.00.mp4 | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00++ small.jpg"; Expected = "2012.12.26_07.40.00 small.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00- big.jpg"; Expected = "2012.12.26_07.40.00 big.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00_1 (3)+.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_07.40.00.000.mp4"; Expected = "2012.12.26_07.40.00.mp4 | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_074000_001.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_074000_02.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "2012.12.26_074000_3.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "20121226-07400099.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "20121226_074000_001_saved.jpg"; Expected = "2012.12.26_07.40.00_saved.jpg | 2012.12.26_07.40.00"},
    @{Input = "20121226_074000.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "20121226_074000_portrait.jpg"; Expected = "2012.12.26_07.40.00_portrait.jpg | 2012.12.26_07.40.00"},
    @{Input = "20121226_074000 (2)+.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "20121226_074000-.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "20121226_074000(0).jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "20121226_074000+.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "20121226_074000++.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "20121226_074000-.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "IMG_20121226_074000_1.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "IMG_20121226_074000.jpg"; Expected = "2012.12.26_07.40.00.jpg | 2012.12.26_07.40.00"},
    @{Input = "VID_20121226_074000.mp4"; Expected = "2012.12.26_07.40.00.mp4 | 2012.12.26_07.40.00"}
)
