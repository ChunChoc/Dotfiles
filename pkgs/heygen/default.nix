{
  lib,
  stdenvNoCC,
  fetchurl,
}:

# CLI `heygen` (https://developers.heygen.com/cli). Upstream solo la distribuye como
# binario estático en su CDN (install.sh); se fija versión y sha256 (checksums.txt oficial).
# Actualizar: cambiar version y hash (curl -fsS https://static.heygen.ai/cli/stable).
stdenvNoCC.mkDerivation rec {
  pname = "heygen";
  version = "0.11.0";

  src = fetchurl {
    url = "https://static.heygen.ai/cli/releases/v${version}/heygen_v${version}_linux_amd64.tar.gz";
    hash = "sha256-n/5R3dQZJir18kr1TPHCqh6UTSWWtQErTFRoMwtSpak=";
  };
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 heygen $out/bin/heygen
    runHook postInstall
  '';

  meta = {
    description = "HeyGen CLI";
    homepage = "https://developers.heygen.com/cli";
    license = lib.licenses.asl20;
    mainProgram = "heygen";
    platforms = [ "x86_64-linux" ];
  };
}
