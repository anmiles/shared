@(
	@{
		Input = (crop -src_width 1920 -src_height 1080 -rect @(0, 0, 1920, 1080));
		Expected = "1920:1080:0:0";
		Comment = "zoom: 1*1, crop: none";
	},
	@{
		Input = (crop -src_width 1920 -src_height 1080 -rect @(400, 200, 1620, 980));
		Expected = "1220:780:400:200";
		Comment = "zoom: 1*1, crop: x,y";
	},
	@{
		Input = (crop -src_width 5760 -src_height 1080 -rect @(0, 0, 1920, 1080));
		Expected = "5760:1080:0:0";
		Comment = "zoom: 3*1, crop: none";
	},
	@{
		Input = (crop -src_width 5760 -src_height 1080 -rect @(400, 200, 1620, 980));
		Expected = "3660:1080:1200:0";
		Comment = "zoom: 3*1, crop: x";
	},
	@{
		Input = (crop -src_width 5760 -src_height 1080 -rect @(400, 400, 1620, 580));
		Expected = "3660:540:1200:120";
		Comment = "zoom: 3*1, crop: x,y";
	},
	@{
		Input = (crop -src_width 1920 -src_height 3240 -rect @(0, 0, 1920, 1080));
		Expected = "1920:3240:0:0";
		Comment = "zoom: 1*3, crop: none";
	},
	@{
		Input = (crop -src_width 1920 -src_height 3240 -rect @(400, 300, 1720, 980));
		Expected = "1920:2040:0:900";
		Comment = "zoom: 1*3, crop: y";
	},
	@{
		Input = (crop -src_width 1920 -src_height 3240 -rect @(800, 300, 1020, 980));
		Expected = "660:2040:480:900";
		Comment = "zoom: 1*3, crop: x,y";
	},
	@{
		Input = (crop -src_width 7680 -src_height 3240 -rect @(0, 0, 1920, 1080));
		Expected = "7680:3240:0:0";
		Comment = "zoom: 4*3, crop: none";
	},
	@{
		Input = (crop -src_width 7680 -src_height 3240 -rect @(400, 200, 1620, 980));
		Expected = "4880:2980:1600:260";
		Comment = "zoom: 4*3, crop: x,y";
	},
	@{
		Input = (crop -src_width 1152 -src_height 1080 -rect @(0, 0, 1920, 1080));
		Expected = "1152:1080:0:0";
		Comment = "zoom: 0.6*1, crop: none";
	},
	@{
		Input = (crop -src_width 1152 -src_height 1080 -rect @(300, 400, 1720, 980));
		Expected = "1152:580:0:400";
		Comment = "zoom: 0.6*1, crop: y";
	},
	@{
		Input = (crop -src_width 1152 -src_height 1080 -rect @(800, 400, 1320, 980));
		Expected = "520:580:416:400";
		Comment = "zoom: 0.6*1, crop: x,y";
	},
	@{
		Input = (crop -src_width 1920 -src_height 720 -rect @(0, 0, 1920, 1080));
		Expected = "1920:720:0:0";
		Comment = "zoom: 1*0.6, crop: none";
	},
	@{
		Input = (crop -src_width 1920 -src_height 720 -rect @(400, 100, 1720, 1030));
		Expected = "1320:720:400:0";
		Comment = "zoom: 1*0.6, crop: x";
	},
	@{
		Input = (crop -src_width 1920 -src_height 720 -rect @(400, 420, 1720, 600));
		Expected = "1320:180:400:240";
		Comment = "zoom: 1*0.6, crop: x,y";
	},
	@{
		Input = (crop -src_width 768 -src_height 324 -rect @(0, 0, 1920, 1080));
		Expected = "768:324:0:0";
		Comment = "zoom: 0.4*0.3, crop: none";
	},
	@{
		Input = (crop -src_width 768 -src_height 324 -rect @(400, 200, 1620, 980));
		Expected = "488:298:160:26";
		Comment = "zoom: 0.4*0.3, crop: x,y";
	}
)
