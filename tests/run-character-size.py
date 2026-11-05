from pathlib import Path
import subprocess, tempfile
root=Path(__file__).resolve().parents[1]
s=(root/'src/main.swift').read_text()
helper=s.split('// MARK: - Character sizing\n',1)[1].split('// MARK: - Sprite sheet',1)[0]
with tempfile.TemporaryDirectory() as tmp:
    test=Path(tmp)/'main.swift'
    test.write_text('import Foundation\n'+helper+(root/'tests/character-size.swift').read_text())
    subprocess.run(['swift','-module-cache-path',str(root/'build/test-module-cache'),str(test)],check=True)
