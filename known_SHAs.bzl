# Hard-codes known SHA of rescript compiler and libaries for security.
known_shas = {
  "9.1.2": {
    "SHA256": "a3805c938fe46a7117a6af6680ba356bb7d45bc42fd9b0fb2bc5ceff7cf6bbc6"
  },
  "9.0.2": {
    "SHA256": "030821edc308a22d1acdab425f004f326aaa69b978f6a3ab8c44392c1996bb78"
  },
  "9.0.1": {
    "SHA256": "dbcdce001b71ed0eaa8fcaebd59e74d01b15a5fb1e569683171d284f31fafe1f"
  },
  "9.0.0": {
    "SHA256": "c1327672fad1dfece6257bc83b587ccceabf2f38ae22aaaf6029b990e82ed956"
  },
  "8.4.2": {
    "SHA256": "ba65060420107826742cf728e76e97d582c5825ae165f56b8a51562324488a10"
  },
}

def get_sha256_if_known(version = ""):
  perhapsSHA = known_shas.get(version) 
  if perhapsSHA != None:
    return perhapsSHA["SHA256"]
  return ""
