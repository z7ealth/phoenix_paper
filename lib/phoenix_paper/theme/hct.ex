defmodule PhoenixPaper.Theme.Hct do
  @moduledoc """
  Material's HCT color space (hue, chroma, tone), used by
  `mix phoenix_paper.gen.theme` to build MD3 color schemes from a seed.

  Hue and chroma come from CAM16 (under Material's default viewing
  conditions); tone is CIELAB L*, so a tone difference is a guaranteed
  contrast difference — which is what makes MD3's tone-based role
  assignments (primary = tone 40, on-primary = tone 100, ...) accessible
  regardless of hue.

  A port of the algorithms in Google's material-color-utilities
  (Apache-2.0): CAM16 forward/inverse and the HCT → sRGB solve. The
  solver here is the library's earlier iterative one (binary searches on
  CAM16 lightness for the exact tone, then on chroma for the most
  saturated in-gamut color) rather than the newer closed-form solver, so
  results can differ from Material Theme Builder by a unit or so of
  chroma; tones are exact to within 0.5.
  """

  import Bitwise

  # ---- sRGB / XYZ / L* --------------------------------------------------

  @srgb_to_xyz {{0.41233895, 0.35762064, 0.18051042}, {0.2126, 0.7152, 0.0722},
                {0.01932141, 0.11916382, 0.95034478}}

  @xyz_to_srgb {{3.2413774792388685, -1.5376652402851851, -0.49885366846268053},
                {-0.9691452513005321, 1.8758853451067872, 0.04156585616912061},
                {0.05562093689691305, -0.20395524564742123, 1.0571799111220335}}

  defp mul({{a, b, c}, {d, e, f}, {g, h, i}}, {x, y, z}),
    do: {a * x + b * y + c * z, d * x + e * y + f * z, g * x + h * y + i * z}

  # sRGB channel (0..255) → linear (0..100), and back.
  defp linearize(channel) do
    n = channel / 255.0
    if n <= 0.040449936, do: n / 12.92 * 100.0, else: :math.pow((n + 0.055) / 1.055, 2.4) * 100.0
  end

  defp delinearize(linear) do
    n = linear / 100.0

    v =
      if n <= 0.0031308,
        do: n * 12.92,
        else: 1.055 * :math.pow(n, 1.0 / 2.4) - 0.055

    v |> Kernel.*(255.0) |> round() |> max(0) |> min(255)
  end

  @doc "L* (0..100) from a relative luminance Y (0..100)."
  def lstar_from_y(y), do: 116.0 * lab_f(y / 100.0) - 16.0

  @doc "Relative luminance Y (0..100) from L* (0..100)."
  def y_from_lstar(lstar), do: 100.0 * lab_invf((lstar + 16.0) / 116.0)

  @e 216.0 / 24389.0
  @kappa 24389.0 / 27.0

  defp lab_f(t), do: if(t > @e, do: :math.pow(t, 1.0 / 3.0), else: (@kappa * t + 16.0) / 116.0)

  defp lab_invf(ft) do
    ft3 = ft * ft * ft
    if ft3 > @e, do: ft3, else: (116.0 * ft - 16.0) / @kappa
  end

  # ---- CAM16 viewing conditions (material-color-utilities defaults) -----

  @m16 {{0.401288, 0.650173, -0.051461}, {-0.250268, 1.204414, 0.045854},
        {-0.002079, 0.048952, 0.953127}}

  @m16_inv {{1.8620678, -1.0112547, 0.14918678}, {0.38752654, 0.62144744, -0.00897398},
            {-0.0158415, -0.03412294, 1.0499644}}

  vc = fn ->
    {xw, yw, zw} = {95.047, 100.0, 108.883}

    mul = fn {{a, b, c}, {d, e, f}, {g, h, i}}, {x, y, z} ->
      {a * x + b * y + c * z, d * x + e * y + f * z, g * x + h * y + i * z}
    end

    adapting_luminance =
      200.0 / :math.pi() * (100.0 * :math.pow((50.0 + 16.0) / 116.0, 3)) / 100.0

    background_lstar = 50.0
    surround = 2.0

    {rw, gw, bw} =
      mul.(
        {{0.401288, 0.650173, -0.051461}, {-0.250268, 1.204414, 0.045854},
         {-0.002079, 0.048952, 0.953127}},
        {xw, yw, zw}
      )

    f = 0.8 + surround / 10.0

    c =
      if f >= 0.9,
        do: 0.59 + (0.69 - 0.59) * ((f - 0.9) * 10.0),
        else: 0.525 + (0.59 - 0.525) * ((f - 0.8) * 10.0)

    d = f * (1.0 - 1.0 / 3.6 * :math.exp((-adapting_luminance - 42.0) / 92.0))
    d = d |> max(0.0) |> min(1.0)
    nc = f
    rgb_d = {d * (100.0 / rw) + 1.0 - d, d * (100.0 / gw) + 1.0 - d, d * (100.0 / bw) + 1.0 - d}
    k = 1.0 / (5.0 * adapting_luminance + 1.0)
    k4 = k * k * k * k
    k4f = 1.0 - k4

    fl =
      k4 * adapting_luminance + 0.1 * k4f * k4f * :math.pow(5.0 * adapting_luminance, 1.0 / 3.0)

    y_bg = 100.0 * :math.pow((background_lstar + 16.0) / 116.0, 3)
    n = y_bg / yw
    z = 1.48 + :math.sqrt(n)
    nbb = 0.725 / :math.pow(n, 0.2)
    {rd, gd, bd} = rgb_d

    af = fn v -> :math.pow(fl * v / 100.0, 0.42) end
    {ra, ga, ba} = {af.(rd * rw), af.(gd * gw), af.(bd * bw)}
    a = fn x -> 400.0 * x / (x + 27.13) end
    aw = (2.0 * a.(ra) + a.(ga) + 0.05 * a.(ba)) * nbb

    %{n: n, aw: aw, nbb: nbb, ncb: nbb, c: c, nc: nc, rgb_d: rgb_d, fl: fl, z: z}
  end

  @vc vc.()

  # ---- CAM16 -----------------------------------------------------------

  @doc "`{hue, chroma, j}` (CAM16) of an `{x, y, z}` (0..100)."
  def cam16_from_xyz(xyz) do
    %{rgb_d: {rd, gd, bd}, fl: fl, nbb: nbb, ncb: ncb, aw: aw, c: c, z: z, nc: nc, n: n} = @vc
    {r_c, g_c, b_c} = mul(@m16, xyz)

    adapt = fn v ->
      af = :math.pow(fl * abs(v) / 100.0, 0.42)
      sign(v) * 400.0 * af / (af + 27.13)
    end

    {ra, ga, ba} = {adapt.(rd * r_c), adapt.(gd * g_c), adapt.(bd * b_c)}

    a = (11.0 * ra + -12.0 * ga + ba) / 11.0
    b = (ra + ga - 2.0 * ba) / 9.0
    u = (20.0 * ra + 20.0 * ga + 21.0 * ba) / 20.0
    p2 = (40.0 * ra + 20.0 * ga + ba) / 20.0

    hue = :math.atan2(b, a) * 180.0 / :math.pi()
    hue = if hue < 0, do: hue + 360.0, else: if(hue >= 360.0, do: hue - 360.0, else: hue)

    ac = p2 * nbb
    j = 100.0 * :math.pow(ac / aw, c * z)

    hue_prime = if hue < 20.14, do: hue + 360.0, else: hue
    e_hue = 0.25 * (:math.cos(hue_prime * :math.pi() / 180.0 + 2.0) + 3.8)
    p1 = 50000.0 / 13.0 * e_hue * nc * ncb
    t = p1 * :math.sqrt(a * a + b * b) / (u + 0.305)
    alpha = :math.pow(t, 0.9) * :math.pow(1.64 - :math.pow(0.29, n), 0.73)
    chroma = alpha * :math.sqrt(j / 100.0)

    {hue, chroma, j}
  end

  @doc "The `{x, y, z}` (0..100) of a CAM16 `j`, `chroma`, `hue`."
  def xyz_from_cam16(j, chroma, hue) do
    %{rgb_d: {rd, gd, bd}, fl: fl, nbb: nbb, ncb: ncb, aw: aw, c: c, z: z, nc: nc, n: n} = @vc

    alpha = if chroma == 0.0 or j == 0.0, do: 0.0, else: chroma / :math.sqrt(j / 100.0)
    t = :math.pow(alpha / :math.pow(1.64 - :math.pow(0.29, n), 0.73), 1.0 / 0.9)
    h_rad = hue * :math.pi() / 180.0
    e_hue = 0.25 * (:math.cos(h_rad + 2.0) + 3.8)
    ac = aw * :math.pow(j / 100.0, 1.0 / c / z)
    p1 = e_hue * (50000.0 / 13.0) * nc * ncb
    p2 = ac / nbb
    h_sin = :math.sin(h_rad)
    h_cos = :math.cos(h_rad)
    gamma = 23.0 * (p2 + 0.305) * t / (23.0 * p1 + 11.0 * t * h_cos + 108.0 * t * h_sin)
    a = gamma * h_cos
    b = gamma * h_sin
    ra = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0
    ga = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0
    ba = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0

    unadapt = fn v ->
      base = max(0.0, 27.13 * abs(v) / (400.0 - abs(v)))
      sign(v) * (100.0 / fl) * :math.pow(base, 1.0 / 0.42)
    end

    mul(@m16_inv, {unadapt.(ra) / rd, unadapt.(ga) / gd, unadapt.(ba) / bd})
  end

  defp sign(v) when v < 0, do: -1.0
  defp sign(v) when v > 0, do: 1.0
  defp sign(_v), do: 0.0

  # ---- HCT ---------------------------------------------------------------

  @doc """
  `{hue, chroma, tone}` of a hex color (`"#6750A4"` or `"6750A4"`).

      iex> {_h, _c, tone} = PhoenixPaper.Theme.Hct.from_hex("#ffffff")
      iex> Float.round(tone, 1)
      100.0
  """
  def from_hex(hex) do
    {r, g, b} = parse_hex(hex)
    xyz = mul(@srgb_to_xyz, {linearize(r), linearize(g), linearize(b)})
    {hue, chroma, _j} = cam16_from_xyz(xyz)
    {_, y, _} = xyz
    {hue, chroma, lstar_from_y(y)}
  end

  @doc """
  The hex color closest to `hue`/`chroma`/`tone`: the exact tone, at the
  requested chroma if it's inside the sRGB gamut, otherwise the highest
  chroma that is.
  """
  def to_hex(hue, chroma, tone) do
    hue = normalize_hue(hue)

    cond do
      tone <= 0.0001 -> "#000000"
      tone >= 99.9999 -> "#ffffff"
      chroma < 0.0001 -> gray(tone)
      true -> solve(hue, chroma, tone)
    end
  end

  @doc "Normalizes a hue into 0..360."
  def normalize_hue(hue) do
    h = :math.fmod(hue, 360.0)
    if h < 0, do: h + 360.0, else: h
  end

  defp gray(tone) do
    c = delinearize(y_from_lstar(tone))
    rgb_hex(c, c, c)
  end

  # For a candidate chroma, binary-search CAM16 J for the exact tone and
  # report the color and whether it's in gamut. Then binary-search the
  # chroma down from the request until it fits.
  defp solve(hue, chroma, tone) do
    case at_chroma(hue, chroma, tone) do
      {:ok, rgb} ->
        to_hex_rgb(rgb)

      :out ->
        {lo, hi} = {0.0, chroma}
        best = chroma_search(hue, tone, lo, hi, 0, nil)
        to_hex_rgb(best || linear_gray(tone))
    end
  end

  defp chroma_search(_hue, _tone, _lo, _hi, 24, best), do: best

  defp chroma_search(hue, tone, lo, hi, i, best) do
    mid = (lo + hi) / 2.0

    case at_chroma(hue, mid, tone) do
      {:ok, rgb} -> chroma_search(hue, tone, mid, hi, i + 1, rgb)
      :out -> chroma_search(hue, tone, lo, mid, i + 1, best)
    end
  end

  defp linear_gray(tone) do
    y = y_from_lstar(tone)
    {y, y, y}
  end

  defp at_chroma(hue, chroma, tone) do
    target_y = y_from_lstar(tone)
    j = j_search(hue, chroma, target_y, 0.0, 100.0, 0)
    {_x, y, _z} = xyz = xyz_from_cam16(j, chroma, hue)
    {r, g, b} = rgb = mul(@xyz_to_srgb, xyz)

    if abs(y - target_y) < 0.02 * max(target_y, 1.0) and in_gamut?(r) and in_gamut?(g) and
         in_gamut?(b),
       do: {:ok, rgb},
       else: :out
  end

  defp in_gamut?(v), do: v >= -0.01 and v <= 100.01

  # Y rises with J at a fixed hue and chroma.
  defp j_search(_hue, _chroma, _target, lo, hi, 40), do: (lo + hi) / 2.0

  defp j_search(hue, chroma, target, lo, hi, i) do
    mid = (lo + hi) / 2.0
    {_x, y, _z} = xyz_from_cam16(mid, chroma, hue)

    if y < target,
      do: j_search(hue, chroma, target, mid, hi, i + 1),
      else: j_search(hue, chroma, target, lo, mid, i + 1)
  end

  defp to_hex_rgb({r, g, b}), do: rgb_hex(delinearize(r), delinearize(g), delinearize(b))

  defp rgb_hex(r, g, b) do
    "#" <>
      Enum.map_join(
        [r, g, b],
        &(&1 |> Integer.to_string(16) |> String.pad_leading(2, "0") |> String.downcase())
      )
  end

  @doc false
  def parse_hex("#" <> hex), do: parse_hex(hex)

  def parse_hex(<<r::binary-size(1), g::binary-size(1), b::binary-size(1)>>),
    do: parse_hex(r <> r <> g <> g <> b <> b)

  def parse_hex(<<_::binary-size(6)>> = hex) do
    int = String.to_integer(hex, 16)
    {int >>> 16 &&& 0xFF, int >>> 8 &&& 0xFF, int &&& 0xFF}
  end

  def parse_hex(other), do: raise(ArgumentError, "not a hex color: #{inspect(other)}")
end
