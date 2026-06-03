${domain} {
	handle /kratos/* {
		uri strip_prefix /kratos
		reverse_proxy kratos:4433
	}

	handle /* {
		# flush_interval -1 disables response buffering so server-streaming
		# RPC writes are flushed to the client immediately.
		reverse_proxy bff:5050 {
			flush_interval -1
		}
	}
}
