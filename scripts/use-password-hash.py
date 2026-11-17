"""Use a launcher-provided SHA-512 crypt hash for Dropbear's root login."""

from pathlib import Path


source = Path("src/svr-authpasswd.c")
original = source.read_text()
system_password = """	if (valid_user && passwordlen <= DROPBEAR_MAX_PASSWORD_LEN) {
		/* the first bytes of passwdcrypt are the salt */
		passwdcrypt = ses.authstate.pw_passwd;
		testcrypt = crypt(password, passwdcrypt);
	}
"""
launcher_password = """	char service_hash[256];
	const char *hash_path = getenv("EMUELEC_SSH_HASH_FILE");
	if (valid_user && ses.authstate.pw_uid == 0 && hash_path &&
			passwordlen <= DROPBEAR_MAX_PASSWORD_LEN) {
		FILE *hash_file = fopen(hash_path, "r");
		if (hash_file) {
			if (fgets(service_hash, sizeof(service_hash), hash_file)) {
				service_hash[strcspn(service_hash, "\\r\\n")] = 0;
				if (strncmp(service_hash, "$6$", 3) == 0) {
					passwdcrypt = service_hash;
					testcrypt = crypt(password, passwdcrypt);
				}
			}
			fclose(hash_file);
		}
	}
"""
if original.count(system_password) != 1:
    raise SystemExit("Unexpected Dropbear source. Review the password adaptation.")
source.write_text(original.replace(system_password, launcher_password))
