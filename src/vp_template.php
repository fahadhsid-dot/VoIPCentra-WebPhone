<!DOCTYPE html>
<!--
*******************************************************************************
*
*    HTML File for the Vicidial WebRTC Phone
*
*    Copyright (C) 2016  Michael Cargile
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU Affero General Public License as
*    published by the Free Software Foundation, either version 3 of the
*    License, or (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU Affero General Public License for more details.
*
*    You should have received a copy of the GNU Affero General Public License
*    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*******************************************************************************
-->
<html manifest="viciphone.appcache">
	<head>
		<title>VoIPCentra WebPhone</title>
		<link rel="stylesheet" href="<?php echo $layout; ?>" />
		<meta http-equiv="Pragma" content="no-cache">
		<meta http-equiv="Expires" content="-1">
		<meta http-equiv="CACHE-CONTROL" content="NO-CACHE">
	</head>
	<body>
		<!-- Container -->
		<div id="container">

			<!-- Main -->
			<div id="main">
				<!-- Video element to handle audio -->
				<audio autoplay width='0' hieght='0' id="audio"></audio>
				<!--<video width='0' hieght='0' id="audio"></video>-->

				<!-- Logo -->
				<section id="logo">
					<img id="logo_img" src="images/voipcentra-logo.svg">
				</section>
				<!-- End Logo -->

				<!-- Controls -->
				<section id="controls">
					<section id="registration_control">
						<input type="text" value="Unregistered" id="reg_status" readonly>
						<button class="button" id="register"><img id="reg_icon" src="images/wp_register_inactive.gif" alt="register"></button>
						<button class="button" id="unregister"><img id="unreg_icon" src="images/wp_unregister_inactive.gif" alt="register"></button>
					</section>
					<section id="dial_control">
						<input type="text" name="digits" value="" id="digits"/>
						<button class="button" id="dial"><img id="dial_icon" src="images/wp_dial.gif" alt="register"></button>
					</section>
					<section id="audio_control">
						<button class="button" id="mic_mute"><img id="mute_icon" src="images/wp_mic_on.gif" alt="mute"></button>
						<button class="button" id="vol_up"><img id="vol_up_icon" src="images/wp_speaker_up.gif" alt="register"></button>
						<button class="button" id="vol_down"><img id="vol_down_icon" src="images/wp_speaker_down.gif" alt="register"></button>
					</section>
				</section>
				<!-- End Controls -->

				<!-- Dialpad -->
				<section id="dialpad">
					<section id="dial_row1">
					<button class="dialpad_button" id="one">1</button>
					<button class="dialpad_button" id="two">2</button>
					<button class="dialpad_button" id="three">3</button>
					</section>
					<section id="dial_row2">
					<button class="dialpad_button" id="four">4</button>
					<button class="dialpad_button" id="five">5</button>
					<button class="dialpad_button" id="six">6</button>
					</section>
					<section id="dial_row3">
					<button class="dialpad_button" id="seven">7</button>
					<button class="dialpad_button" id="eight">8</button>
					<button class="dialpad_button" id="nine">9</button>
					</section>
					<section id="dial_row4">
					<button class="dialpad_button" id="star">*</button>
					<button class="dialpad_button" id="zero">0</button>
					<button class="dialpad_button" id="pound">#</button>
					</section>
					<section id="dial_dtmf">
					<input type="text" name="dtmf_digits" value="" id="dtmf_digits"/>
					<button class="button" id="send_dtmf">Send</button>
					</section>
				</section>
				<!-- End Dialpad -->

			<div id="vc-footer">
<a href="https://voipcentra.net/" target="_blank" rel="noopener noreferrer">voipcentra.net</a>
</div>
</div>
			<!-- End Main -->

		</div>
		<!-- End Container -->

		<!-- Debug Output -->

<div id="debug"></div>

		<!-- <?php echo "$options $settings"; ?> -->

		<!-- variables to pass vici_phone.js -->
		<script>

		// SIP configuration variables
		var cid_name = <?php echo json_encode((string) $cid_name, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var sip_uri = <?php echo json_encode((string) $sip_uri, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var auth_user = <?php echo json_encode((string) $auth_user, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var password = <?php echo json_encode((string) $password, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var ws_server = <?php echo json_encode((string) $ws_server, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;

		// whether debug should be enabled
		var debug_enabled = <?php echo json_encode((string) $debug_enabled, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;

		// display restriction options
		var hide_dialpad = <?php echo json_encode((string) $hide_dialpad, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var hide_dialbox = <?php echo json_encode((string) $hide_dialbox, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var hide_mute = <?php echo json_encode((string) $hide_mute, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var hide_volume = <?php echo json_encode((string) $hide_volume, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;

		// audio settings
		var auto_gain = <?php echo json_encode((string) ($auto_gain_control ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var echo_can = <?php echo json_encode((string) ($echo_cancellation ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var noise_sup = <?php echo json_encode((string) ($noise_suppression ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;

		// behavior options
		var auto_answer = <?php echo json_encode((string) $auto_answer, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var dial_reg_exten = <?php echo json_encode((string) ($dial_reg_exten ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var reg_exten = <?php echo json_encode((string) $session_id, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var region = <?php echo json_encode((string) ($progress_region ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;

		var langAttempting 		= <?php echo json_encode((string) ($langAttempting ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langConnected 		= <?php echo json_encode((string) ($langConnected ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langDisconnected 		= <?php echo json_encode((string) ($langDisconnected ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langExten 			= <?php echo json_encode((string) ($langExten ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langIncall 			= <?php echo json_encode((string) ($langIncall ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langInit 			= <?php echo json_encode((string) ($langInit ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langRedirect 		= <?php echo json_encode((string) ($langRedirect ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langRegFailed 		= <?php echo json_encode((string) ($langRegFailed ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langRegistering 		= <?php echo json_encode((string) ($langRegistering ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langRegistered 		= <?php echo json_encode((string) ($langRegistered ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langReject 			= <?php echo json_encode((string) ($langReject ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langRinging 		= <?php echo json_encode((string) ($langRinging ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langSend 			= <?php echo json_encode((string) ($langSend ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langTrying 			= <?php echo json_encode((string) ($langTrying ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langUnregFailed 		= <?php echo json_encode((string) ($langUnregFailed ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langUnregistered 		= <?php echo json_encode((string) ($langUnregistered ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langUnregistering		= <?php echo json_encode((string) ($langUnregistering ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
		var langWebrtcError 		= <?php echo json_encode((string) ($langWebrtcError ?? ''), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;


		</script>

		<!-- WebRTC adapter -->
		<!--<script src="js/adapter.js"></script>-->
		<!--<script src="https://webrtc.github.io/adapter/adapter-latest.js"></script> -->

		<!-- SIP.js library -->
		<script  type="text/javascript" src="js/sip.js"></script>

		<!-- Our Java Script Code -->
		<script  type="text/javascript" src="js/vici_phone.js"></script>

	</body>
</html>

