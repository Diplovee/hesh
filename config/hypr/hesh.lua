-- Hesh standalone device windows.
-- The em-dash title suffix is unique to child device hosts, so the main Hesh
-- workspace window remains governed by the normal layout.
o.window({ title = ".* — Hesh$" }, {
  float = true,
  center = true,
  -- Keep the preview crisp while retaining compositor borders and shadows.
  tag = "-default-opacity",
  opacity = "1 1",
  no_blur = true,
  no_dim = true,
})
