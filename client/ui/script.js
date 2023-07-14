$(function () {
	let root = "xnote";
	var json = JSON;
	var print = console.log;
	const rand=()=>Math.random(0).toString(36).substr(2);
	const token=(length)=>(rand()+rand()+rand()+rand()).substr(0,length);
	var Listeners = [];

	function doPost(script, endpoint, data){
		if (script && endpoint){
			if (!data){data = {}}
			let cb = $.post('http://'+script+'/'+endpoint, JSON.stringify(data));
			return cb;
		}
	}


	// Exit Check
	document.onkeyup = function (data) {
		if (data.which === 27) {
			console.log('res', root)
			doPost(root, "exit", {})
		}
	};

	// Listeners Event
	window.addEventListener("message", t => {
		console.log("NOTE GOT EVENT", t.data.type)
		let e = t.data.type;
		Listeners[e] && Listeners[e](t.data)
	})
	Listeners.setroot = function (data) {
		console.log('setting res name')
		console.log(JSON.stringify(data))
		if (data.res != null) {

			root = data.res;
		}
	}
	Listeners.display = function (data) {
		console.log("DOING DISPLAY FOR NOTE", data.state)
		if (data.state === true) {
			$("#cardAll").fadeIn()
		}else {
			$("#cardAll").fadeOut()
		}
	}

	let fC = false;
	$("#writeNames").focus(function (e) {
		print("Focused On to this text shit")
		if (fC) {
			let wow = $( this )
			let elem = wow.get( 0 )
			let me = e.target;
			elem.value = elem.value;

			var range = document.createRange()
			var sel = window.getSelection()
			let index = wow.text().length > 0 && 1 || 0;
			print(index, wow.text().length)
			range.setStart(me, index)
			range.collapse(true)

			sel.removeAllRanges()
			sel.addRange(range)
			fC = false;
		}


		// if(elem != null) {
		// 	if(elem.createTextRange) {
		// 		var range = elem.createTextRange();
		// 		range.move('character', caretPos);
		// 		range.select();
		// 	} else {
		// 		if(elem.selectionStart) {
		// 			elem.focus();
		// 			elem.setSelectionRange(caretPos, caretPos);
		// 		}else {
		// 			elem.focus();
		// 		}
		// 	}
		// }
	})

	$(document).bind('click', function(e) {
		let target = $(e.target);
		let p = $("#writeNames");
		if(!target.is('p') && target.hasClass("sheet") && !p.is(":focus")) {

			var tmp = p.val();
			fC = true;
			p.focus()
		}
	});

	$('#writeNames').on('input',function(e){
		doPost(root, "setText", {str: $('#writeNames').text()})
	});
})
