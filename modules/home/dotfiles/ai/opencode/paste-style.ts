import { Plugin } from "@opencode/plugin/tui"
import type { SyntaxStyle } from "@opentui/core"

export default Plugin.define({
  id: "dms.paste-style",
  setup(context) {
    const { renderer } = context
    const token = "extmark.paste"
    const originals = new WeakMap<SyntaxStyle, NonNullable<ReturnType<SyntaxStyle["getStyle"]>>>()
    let prompt: typeof renderer.currentFocusedEditor = null

    // OpenCode usa el color de advertencia para los adjuntos y el texto pegado.
    // Conservar el ID del estilo para que también se recoloreen los adjuntos existentes.
    const recolor = async () => {
      const editor = renderer.currentFocusedEditor
      const style = editor?.syntaxStyle
      if (!editor || !style) return

      if (originals.has(style)) {
        prompt = editor
        return
      }

      const original = style.getStyle(token)
      if (!original) return

      const { text, background } = context.theme
      style.registerStyle(token, { ...original, fg: text.base, bg: background.raised.max })
      originals.set(style, original)
      prompt = editor
      editor.syntaxStyle = style
    }

    renderer.setFrameCallback(recolor)
    renderer.requestRender()
    return () => {
      renderer.removeFrameCallback(recolor)
      if (!prompt || prompt.isDestroyed) return

      const style = prompt.syntaxStyle
      if (!style) return

      const original = originals.get(style)
      if (original) {
        style.registerStyle(token, original)
        prompt.syntaxStyle = style
      }
    }
  },
})
