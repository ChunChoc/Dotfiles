{
  espeak-ng,
  fetchurl,
  python3,
  writeTextDir,
}:

# Python para `hyperframes tts` (voz en off local con Kokoro-82M).
# La CLI lo recibe por HYPERFRAMES_PYTHON; así no hace falta `pip install`.
let
  ps = python3.pkgs;

  # espeakng-loader en PyPI trae una libespeak-ng.so precompilada (no corre en NixOS).
  # Este reemplazo expone la misma API apuntando al espeak-ng de nixpkgs.
  espeakng-loader = ps.buildPythonPackage {
    pname = "espeakng-loader";
    version = "0.2.4";
    pyproject = true;
    build-system = [ ps.setuptools ];
    src = writeTextDir "src" "";
    unpackPhase = ''
      mkdir -p espeakng_loader
      cat > pyproject.toml <<'EOF'
      [project]
      name = "espeakng-loader"
      version = "0.2.4"
      [tool.setuptools]
      packages = ["espeakng_loader"]
      EOF
      cat > espeakng_loader/__init__.py <<'EOF'
      import ctypes

      def get_library_path():
          return "${espeak-ng}/lib/libespeak-ng.so"

      def get_data_path():
          return "${espeak-ng}/share/espeak-ng-data"

      def load_library():
          return ctypes.cdll.LoadLibrary(get_library_path())

      def make_library_available():
          load_library()
      EOF
    '';
    pythonImportsCheck = [ "espeakng_loader" ];
  };

  kokoro-onnx = ps.buildPythonPackage rec {
    pname = "kokoro-onnx";
    version = "0.6.1";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/60/e1/a27e5a70a525a5ee1fd5357596f07b724d02ff317f134e86cb6e3d9db968/kokoro_onnx-${version}-py3-none-any.whl";
      hash = "sha256-UMjeSVDWAd9BQo7lRipIyKeL70Qb9nHySS4HDvRNijI=";
    };
    dependencies = [
      espeakng-loader
      ps.colorlog
      ps.numpy
      ps.onnxruntime
      ps.phonemizer
    ];
    pythonImportsCheck = [ "kokoro_onnx" ];
  };
in
python3.withPackages (_: [
  kokoro-onnx
  ps.soundfile
])
