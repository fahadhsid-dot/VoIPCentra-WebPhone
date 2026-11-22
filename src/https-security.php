<?php
/**
 * VoIPCentra HTTPS transport validation.
 *
 * Direct HTTPS only. Reverse-proxy trust requires an
 * explicitly configured and independently secured deployment.
 */
function voipcentra_is_https_request($server) {
    if (!is_array($server)) {
        return false;
    }

    $https = isset($server['HTTPS'])
        ? strtolower(trim((string) $server['HTTPS']))
        : '';

    return in_array($https, array('on', '1'), true);
}
