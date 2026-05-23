${domain} {
	handle /kratos/* {
		uri strip_prefix /kratos
		reverse_proxy kratos:4433
	}

	handle /* {
		reverse_proxy bff:5050
	}
}
