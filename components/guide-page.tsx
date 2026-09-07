import type { ReactNode } from "react";
import {
  Cpu,
  ExternalLink,
  HardDrive,
  MemoryStick,
  Monitor,
  PlugZap,
  Usb,
  Wifi,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { DecisionHelper } from "@/components/decision-helper";
import { FaqList, ImageTabs } from "@/components/interactive";
import {
  downloads,
  extractFlow,
  features,
  phases,
  sources,
  specs,
  steps,
  type GuideLink,
} from "@/lib/guide";

const nav = [
  { href: "#goal", label: "Goal" },
  { href: "#downloads", label: "Downloads" },
  { href: "#board", label: "Board" },
  { href: "#image", label: "Image" },
  { href: "#bringup", label: "Bring-up" },
  { href: "#extract", label: "FlyOS extract" },
  { href: "#features", label: "Hardware" },
  { href: "#faq", label: "FAQ" },
];

const likelihoodStyle: Record<string, string> = {
  High: "text-emerald-300",
  Likely: "text-emerald-200",
  "Medium-high": "text-amber-100",
  Medium: "text-amber-200",
  "Low until Fly DTB": "text-red-300",
  Expected: "text-emerald-300",
  Hardware: "text-emerald-200",
  "First experiment": "text-amber-100",
  Plausible: "text-amber-200",
  "Extract from FlyOS": "text-amber-200",
  "May differ": "text-muted-foreground",
  "FlyOS userspace": "text-red-300",
};

export function GuidePage() {
  return (
    <div className="min-h-full">
      <div className="pointer-events-none fixed inset-0 bg-[radial-gradient(circle_at_top_left,rgba(232,160,74,0.12),transparent_32%),radial-gradient(circle_at_80%_0%,rgba(120,80,40,0.18),transparent_28%)]" />
      <div className="pointer-events-none fixed inset-0 opacity-[0.07] [background-image:linear-gradient(to_right,rgba(255,255,255,0.12)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.12)_1px,transparent_1px)] [background-size:48px_48px]" />

      <header className="relative border-b border-border/80 bg-background/80 backdrop-blur">
        <div className="mx-auto flex max-w-6xl flex-col gap-6 px-4 py-6 sm:px-6 lg:flex-row lg:items-end lg:justify-between">
          <div className="space-y-3">
            <p className="font-mono text-xs tracking-[0.24em] text-primary uppercase">
              Debian on H3
            </p>
            <h1 className="max-w-2xl text-3xl font-semibold tracking-tight text-balance sm:text-4xl">
              Fly Lite 2.1, as much of the board as Debian will take
            </h1>
            <p className="max-w-2xl text-sm leading-6 text-muted-foreground sm:text-base">
              Goal: a real Debian userspace with apt, and every connector that
              can be enabled without Mellow’s locked FlyOS-FAST image. Start
              from Orange Pi Lite. Steal the rest from the official H3 DTB.
            </p>
          </div>
          <nav className="flex flex-wrap gap-2 text-sm">
            {nav.map((item) => (
              <a
                key={item.href}
                href={item.href}
                className="rounded-full border border-border bg-card/70 px-3 py-1.5 text-muted-foreground transition-colors hover:border-primary/50 hover:text-foreground"
              >
                {item.label}
              </a>
            ))}
          </nav>
        </div>
      </header>

      <main className="relative mx-auto flex max-w-6xl flex-col gap-16 px-4 py-10 sm:px-6 sm:py-14">
        <section id="goal" className="space-y-6">
          <SectionHeading
            kicker="01"
            title="What is actually possible"
            text="The Lite 2.1 is an Allwinner H3 computer. Debian is not a hack. Full FlyOS appliance behaviour is not the target. Working USB, Wi-Fi, console, and then the display ports is."
          />
          <div className="grid gap-4 md:grid-cols-3">
            <Card className="border-emerald-500/30 bg-emerald-950/40">
              <CardHeader>
                <Badge variant="outline">Do this</Badge>
                <CardTitle className="text-lg">Debian 12 on the SD card</CardTitle>
              </CardHeader>
              <CardContent className="text-sm leading-6 text-muted-foreground">
                Armbian Bookworm CLI. Normal users, apt, sshd, NetworkManager.
                This is a usable Linux host, not FlyOS with the locks picked.
              </CardContent>
            </Card>
            <Card className="border-amber-400/30 bg-amber-950/35">
              <CardHeader>
                <Badge variant="outline">Then this</Badge>
                <CardTitle className="text-lg">Enable hardware in order</CardTitle>
              </CardHeader>
              <CardContent className="text-sm leading-6 text-muted-foreground">
                Console, USB, Wi-Fi, HDMI, TFT. Each step has a probe command.
                Stop guessing pinmux until the official DTB says what Mellow
                wired.
              </CardContent>
            </Card>
            <Card className="border-red-400/30 bg-red-950/35">
              <CardHeader>
                <Badge variant="outline">Not the goal</Badge>
                <CardTitle className="text-lg">Clone FlyOS-FAST</CardTitle>
              </CardHeader>
              <CardContent className="text-sm leading-6 text-muted-foreground">
                OTA, KPPM scripts, auto MCU flash, and the read-only root are
                Mellow product. You can port pieces later. They are not required
                for Debian to own the board.
              </CardContent>
            </Card>
          </div>
        </section>

        <section id="downloads" className="space-y-6">
          <SectionHeading
            kicker="02"
            title="Downloads"
            text="These are the pages you actually click. Image short URLs follow Armbian’s current trunk; if a filename changes, use the board page."
          />
          <div className="grid gap-4 lg:grid-cols-2">
            <DownloadGroup
              title="Debian image (start here)"
              links={downloads.debian}
            />
            <DownloadGroup
              title="Flash tools"
              links={downloads.tools}
            />
            <DownloadGroup
              title="Official FlyOS (loot the DTB, do not stay on FAST)"
              links={downloads.flyos}
            />
            <DownloadGroup
              title="Rebuild and alternatives"
              links={downloads.build}
            />
          </div>
        </section>

        <section id="board" className="space-y-6">
          <SectionHeading
            kicker="02"
            title="The board, without the marketing"
            text="Mellow sells this as a Pi replacement. Electrically it is a compact Orange Pi Lite cousin with Fly connectors."
          />
          <div className="grid gap-4 lg:grid-cols-[1.1fr_0.9fr]">
            <Card>
              <CardHeader>
                <CardTitle>Fly-Pi-lite2.1</CardTitle>
                <CardDescription>
                  Official specs. Same generation as{" "}
                  <OutLink href="https://www.armbian.com/orange-pi-lite/">
                    Orange Pi Lite
                  </OutLink>
                  . Product page:{" "}
                  <OutLink href="https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/">
                    FLY Lite 2.1 docs
                  </OutLink>
                  .
                </CardDescription>
              </CardHeader>
              <CardContent className="grid gap-3 sm:grid-cols-2">
                {specs.map((spec) => (
                  <div
                    key={spec.label}
                    className="rounded-lg border border-border/80 bg-muted/30 px-3 py-3"
                  >
                    <p className="font-mono text-[11px] tracking-wide text-primary uppercase">
                      {spec.label}
                    </p>
                    <p className="mt-1 text-sm">{spec.value}</p>
                  </div>
                ))}
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle>Why Orange Pi Lite is the starting DTB</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3 text-sm leading-6 text-muted-foreground">
                <p>
                  Mainline <code className="font-mono text-xs">sun8i-h3-orangepi-lite.dts</code> already
                  describes an H3, 512 MB, SD boot, two USB hosts, HDMI, UART0,
                  and an RTL8189-class SDIO Wi-Fi on MMC1. That is the Lite 2.1
                  feature list with different silk screen.
                </p>
                <p>
                  What Fly changed is the Type-C serial path, the FPC display
                  connectors, LED GPIOs, and maybe the Wi-Fi power/reset GPIO.
                  Those are overlays or a DTB diff, not a new SoC port.
                </p>
              </CardContent>
            </Card>
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <Fact icon={Cpu} label="SoC" value="sun8i-H3, armhf" />
            <Fact icon={MemoryStick} label="RAM" value="512 MB DDR3" />
            <Fact icon={Wifi} label="Radio" value="2.4 GHz SDIO" />
            <Fact icon={HardDrive} label="Install" value="MicroSD only" />
          </div>
        </section>

        <section id="image" className="space-y-6">
          <SectionHeading
            kicker="03"
            title="Which Debian image to flash"
            text="Use a public H3 image first. A custom Armbian board config is a later refinement, not the first boot."
          />
          <ImageTabs />
        </section>

        <section id="bringup" className="space-y-6">
          <SectionHeading
            kicker="04"
            title="Bring-up order"
            text="Likelihood is for a stock Orange Pi Lite Armbian image on this PCB, before any Fly DTB work."
          />
          <div className="grid gap-3 md:grid-cols-2">
            {phases.map((phase) => (
              <Card key={phase.id}>
                <CardHeader>
                  <div className="flex items-center justify-between gap-2">
                    <CardTitle className="text-base">{phase.title}</CardTitle>
                    <span
                      className={`font-mono text-xs ${likelihoodStyle[phase.likelihood] ?? ""}`}
                    >
                      {phase.likelihood}
                    </span>
                  </div>
                </CardHeader>
                <CardContent className="text-sm leading-6 text-muted-foreground">
                  {phase.summary}
                </CardContent>
              </Card>
            ))}
          </div>
          <ol className="grid gap-3">
            {steps.map((step, index) => (
              <li
                key={step.title}
                className="grid gap-3 rounded-xl border border-border bg-card/80 p-4 sm:grid-cols-[auto_1fr] sm:items-start"
              >
                <span className="font-mono text-sm text-primary">
                  {String(index + 1).padStart(2, "0")}
                </span>
                <div>
                  <p className="font-medium">{step.title}</p>
                  <p className="mt-1 text-sm leading-6 text-muted-foreground">
                    {step.body}
                  </p>
                </div>
              </li>
            ))}
          </ol>
          <Card className="border-primary/25">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <PlugZap className="size-4 text-primary" />
                Probe commands on the board
              </CardTitle>
              <CardDescription>
                Also shipped as <code>scripts/first-boot-checks.sh</code>.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <pre className="overflow-x-auto rounded-lg bg-black/40 p-4 font-mono text-xs leading-6 text-amber-100">
                {`uname -a
cat /proc/device-tree/model
dmesg | egrep -i 'mmc|sdio|wlan|rtl|usb|hdmi|spi|uart|musb|gadget'
ls /sys/bus/mmc/devices
lsusb
ip -br link
ls /dev/fb* /dev/dri/card* 2>/dev/null
nmcli dev status`}
              </pre>
            </CardContent>
          </Card>
        </section>

        <section id="extract" className="space-y-6">
          <SectionHeading
            kicker="05"
            title="When the public DTB is not enough"
            text="Fly’s official H3 image is the only complete description of this PCB. You do not run FAST. You loot it."
          />
          <div className="grid gap-3">
            {extractFlow.map((item, index) => (
              <div
                key={item.title}
                className="grid gap-3 rounded-xl border border-border bg-card/80 p-4 sm:grid-cols-[auto_1fr]"
              >
                <span className="font-mono text-sm text-primary">
                  {String(index + 1).padStart(2, "0")}
                </span>
                <div>
                  <p className="font-medium">{item.title}</p>
                  <p className="mt-1 text-sm leading-6 text-muted-foreground">
                    {item.body}
                  </p>
                </div>
              </div>
            ))}
          </div>
          <DownloadGroup
            title="Official H3 FlyOS pages"
            links={downloads.flyos}
          />
          <Card>
            <CardHeader>
              <CardTitle>Extractor</CardTitle>
              <CardDescription>
                Run on a Linux PC with the official image. Needs sudo to mount
                partitions.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <pre className="overflow-x-auto rounded-lg bg-black/40 p-4 font-mono text-xs leading-6 text-amber-100">
                {`./scripts/extract-flyos.sh ~/Downloads/FlyOS_h3_*.img
# writes out/flyos-extract/{dtb,overlays,firmware,REPORT.md}`}
              </pre>
            </CardContent>
          </Card>
        </section>

        <section id="features" className="space-y-6">
          <SectionHeading
            kicker="06"
            title="Connector by connector"
            text="Expected means the Orange Pi Lite DTB already describes it. Everything else is a measured experiment."
          />
          <div className="overflow-x-auto rounded-xl ring-1 ring-foreground/10">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="min-w-44 pl-4">Function</TableHead>
                  <TableHead>On stock OPi Lite Debian</TableHead>
                  <TableHead className="min-w-80 pr-4">What to do</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {features.map((row) => (
                  <TableRow key={row.name}>
                    <TableCell className="pl-4 font-medium">{row.name}</TableCell>
                    <TableCell className={likelihoodStyle[row.status]}>
                      {row.status}
                    </TableCell>
                    <TableCell className="pr-4 text-muted-foreground">
                      {row.how}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <div className="grid gap-3 sm:grid-cols-3">
            <Fact icon={Usb} label="First proof" value="USB-A host" />
            <Fact icon={Wifi} label="Second proof" value="MMC1 / wlan0" />
            <Fact icon={Monitor} label="Last" value="FPC-HDMI, then TFT" />
          </div>
        </section>

        <section id="repo" className="space-y-6">
          <SectionHeading
            kicker="07"
            title="What is in this repo"
            text="Scripts and overlays you can take to a workbench. Overlays that touch TFT pins are candidates, not a claim that this PCB was probed here."
          />
          <div className="grid gap-4 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>scripts/</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2 text-sm leading-6 text-muted-foreground">
                <p>
                  <code className="font-mono text-xs">extract-flyos.sh</code> —
                  mount a FlyOS H3 image and copy DTB, overlays, firmware, and
                  Wi-Fi modules into a report folder.
                </p>
                <p>
                  <code className="font-mono text-xs">first-boot-checks.sh</code>{" "}
                  — run on the Lite after Debian boots. Prints the evidence you
                  need before changing pinmux.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle>overlays/</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2 text-sm leading-6 text-muted-foreground">
                <p>
                  <code className="font-mono text-xs">sdio-wifi-rtl8189.dts</code>{" "}
                  — force MMC1 on if a generic image left SDIO Wi-Fi disabled.
                </p>
                <p>
                  <code className="font-mono text-xs">usb-otg-peripheral.dts</code>{" "}
                  — musb in peripheral mode for Type-C gadget serial.
                </p>
                <p>
                  <code className="font-mono text-xs">fly-tft-spi-candidate.dts</code>{" "}
                  — community H3 SPI TFT starting point. Do not apply until the
                  FlyOS DTB confirms the pins.
                </p>
              </CardContent>
            </Card>
          </div>
        </section>

        <section id="decide" className="space-y-6">
          <SectionHeading
            kicker="08"
            title="Pick the first experiment"
            text="If you only do one thing this week: spare card, Orange Pi Lite Armbian, console or USB dongle, no displays."
          />
          <DecisionHelper />
        </section>

        <section id="faq" className="space-y-6">
          <SectionHeading kicker="09" title="FAQ" />
          <Card>
            <CardContent>
              <FaqList />
            </CardContent>
          </Card>
        </section>

        <section id="sources" className="space-y-4 pb-8">
          <SectionHeading
            kicker="10"
            title="Sources"
            text="Public Mellow docs and mainline sunxi board files. This is not an official Mellow Debian port."
          />
          <ul className="grid gap-2 sm:grid-cols-2">
            {sources.map((source) => (
              <li key={source.href}>
                <a
                  href={source.href}
                  target="_blank"
                  rel="noreferrer"
                  className="flex items-center justify-between gap-2 rounded-lg border border-border bg-card px-3 py-3 text-sm transition-colors hover:border-primary/50"
                >
                  <span>{source.label}</span>
                  <ExternalLink className="size-3.5 shrink-0 text-primary" />
                </a>
              </li>
            ))}
          </ul>
        </section>
      </main>
    </div>
  );
}

function SectionHeading({
  kicker,
  title,
  text,
}: {
  kicker: string;
  title: string;
  text?: string;
}) {
  return (
    <div className="space-y-2">
      <p className="font-mono text-xs tracking-[0.2em] text-primary uppercase">
        {kicker}
      </p>
      <h2 className="text-2xl font-semibold tracking-tight">{title}</h2>
      {text ? (
        <p className="max-w-3xl text-sm leading-6 text-muted-foreground sm:text-base">
          {text}
        </p>
      ) : null}
    </div>
  );
}

function Fact({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof Cpu;
  label: string;
  value: string;
}) {
  return (
    <div className="flex items-start gap-3 rounded-xl border border-border bg-card/70 px-3 py-3">
      <Icon className="mt-0.5 size-4 text-primary" />
      <div>
        <p className="font-mono text-[11px] tracking-wide text-muted-foreground uppercase">
          {label}
        </p>
        <p className="text-sm font-medium">{value}</p>
      </div>
    </div>
  );
}

function DownloadGroup({
  title,
  links,
}: {
  title: string;
  links: GuideLink[];
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <LinkList links={links} />
      </CardContent>
    </Card>
  );
}

function LinkList({ links }: { links: GuideLink[] }) {
  return (
    <ul className="space-y-3">
      {links.map((link) => (
        <li key={link.href} className="space-y-1">
          <OutLink href={link.href}>{link.label}</OutLink>
          {link.note ? (
            <p className="text-xs leading-5 text-muted-foreground">{link.note}</p>
          ) : null}
        </li>
      ))}
    </ul>
  );
}

function OutLink({
  href,
  children,
}: {
  href: string;
  children: ReactNode;
}) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noreferrer"
      className="inline-flex items-center gap-1.5 text-sm font-medium text-primary underline-offset-4 hover:underline"
    >
      {children}
      <ExternalLink className="size-3.5 shrink-0" />
    </a>
  );
}
