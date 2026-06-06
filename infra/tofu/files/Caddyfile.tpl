${domain} {
	handle /kratos/* {
		uri strip_prefix /kratos
		reverse_proxy kratos:4433
	}

	handle /* {
		# The bff upstream lives in a separate file so the
		# blue-green deploy (deploy.sh) can flip blue<->green by rewriting it
		# in place + `caddy reload` without touching this templated file.
		# The snippet additionally carries `flush_interval -1` (disables response buffering
		# so server-streaming RPC writes flush immediately).
		import /etc/caddy/bff_upstream.caddy
	}
}
