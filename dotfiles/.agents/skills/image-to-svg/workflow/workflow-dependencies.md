# Dependencies

This skill requires several CLI tools. Check and install them at the start of every project — before cropping, tracing, or rendering.

## Installation Policy

**NEVER install tools globally.** All tools must be installed to the project directory or user-local paths. This includes:
- No `npm install -g` (use local `node_modules/` or project-local installs)
- No `pip install` system-wide (use virtual environments in the project directory)
- No `cargo install` to default global location (use `--root` to specify project directory)
- No `brew install` or `apt install` without explicit user approval

**Rationale:** Global installs pollute the system, may conflict with other projects, and require elevated privileges. Project-local installs are self-contained, reproducible, and don't need sudo.

## Required Tools

### ImageMagick 7 (`magick`)

Used for: cropping references, measuring coordinates, extracting color palettes, generating diffs, silhouette comparison.

```bash
command -v magick || echo "Install: brew install imagemagick (macOS) or apt install imagemagick (Linux)"

# Verify version 7+ (needed for -kmeans)
magick --version | head -1
```

### librsvg (`rsvg-convert`)

Used for: rendering SVGs to PNG at every iteration step, and for final pixel-perfect verification.

```bash
command -v rsvg-convert || echo "Install: brew install librsvg (macOS) or apt install librsvg2-bin (Linux)"
```

### xmllint

Used for: validating SVG XML before rendering (catches malformed markup with clear error messages).

```bash
command -v xmllint || echo "Install: brew install libxml2 (macOS) or apt install libxml2-utils (Linux)"
```

Usually pre-installed on macOS and most Linux distributions.

## Optional Tools

### VTracer (Rust: `vtracer`)

Used for: auto-tracing feature crops to extract structured metadata (color palettes, sub-element positions, sizes, topology). See `workflow/workflow-trace-metadata.md`.

```bash
# Check if available
command -v vtracer || echo "vtracer not installed"
```

**Install to project directory (NOT global):**

```bash
# Option 1: Install to project-local cargo root
cargo install vtracer --root "$PROJECT_DIR/.cargo"

# Option 2: If using cargo-binstall for pre-built binaries
cargo binstall vtracer --root "$PROJECT_DIR/.cargo"

# After installation, add to PATH for this session
export PATH="$PROJECT_DIR/.cargo/bin:$PATH"
```

If Rust/Cargo is not available, fall back to ImageMagick-only color extraction (see "Fallback" in `workflow/workflow-trace-metadata.md`).

### SVGO (Node.js: `svgo`)

Used for: optimizing the final composite SVG before delivery (25-40% file size reduction).

```bash
command -v svgo || echo "Install: npm install -g svgo"
```

**Install to project directory (NOT global):**

```bash
# Install to local node_modules
npm install svgo

# Run via npx
npx svgo final.svg -o final.svg \
  --config='{"plugins":[{"name":"preset-default","params":{"overrides":{"cleanupIds":false,"collapseGroups":false,"convertShapeToPath":false}}}]}'
```

If Node.js is not available, skip the SVGO optimization step — the SVG is still valid without it. SVGO is a polish step, not a quality gate.

## Python Dependencies

Some tools require Python packages. These MUST be installed in a virtual environment within the project directory — never system-wide.

Current Python dependencies:
- `pyyaml` — parses `feature-locations.yml` for the batch crop script

### Step 1: Create venv in project directory

```bash
python3 -m venv "$PROJECT_DIR/.venv"
source "$PROJECT_DIR/.venv/bin/activate"
```

### Step 2: Install Python packages

```bash
pip install pyyaml
```

### Step 3: Verify

```bash
python3 -c "import yaml; print('pyyaml available')" 2>/dev/null || echo "pyyaml not available"
```

### When the venv is not available

If Python is not available or the user declines to set up a venv:
- **Batch cropping:** Fall back to running individual `magick ... -crop` commands manually from the `feature-locations.yml` values (the YAML is still the source of truth — just read the coordinates by eye).
- The skill still works — Python packages are enhancements, not requirements.

## Dependency Check Script

Run this at the start of every project to verify the environment:

```bash
echo "=== Required ==="
command -v magick      && echo "✓ ImageMagick $(magick --version | head -1 | awk '{print $3}')" || echo "✗ ImageMagick — install with: brew install imagemagick"
command -v rsvg-convert && echo "✓ rsvg-convert" || echo "✗ rsvg-convert — install with: brew install librsvg"
command -v xmllint     && echo "✓ xmllint" || echo "✗ xmllint — install with: brew install libxml2"

echo ""
echo "=== Optional ==="
command -v vtracer     && echo "✓ vtracer (Rust)" || echo "○ vtracer — cargo install vtracer --root \$PROJECT_DIR/.cargo"
python3 -c "import yaml" 2>/dev/null && echo "✓ pyyaml (Python)" || echo "○ pyyaml — pip install pyyaml (in .venv)"
command -v svgo        && echo "✓ SVGO $(svgo --version 2>/dev/null)" || echo "○ SVGO — npm install svgo (local)"

echo ""
echo "=== Installation Policy ==="
echo "⚠ NEVER install tools globally. Use project-local installs only."
echo "  - vtracer: cargo install vtracer --root \$PROJECT_DIR/.cargo"
echo "  - pyyaml: python3 -m venv .venv && pip install pyyaml"
echo "  - svgo: npm install svgo (local)"
```
