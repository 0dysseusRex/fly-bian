import {
  Cable,
  Cpu,
  HardDrive,
  MemoryStick,
  Monitor,
  Router,
  ShieldAlert,
  Usb,
  Wifi,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "@/components/ui/accordion";
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { DecisionHelper } from "@/components/decision-helper";
import {
  faqs,
  features,
  flyosBlockers,
  planSteps,
  ramBudget,
  sources,
  specs,
  verdicts,
} from "@/lib/guide";

const nav = [
  { href: "#verdict", label: "Verdict" },
  { href: "#board", label: "Board" },
  { href: "#simpleaf", label: "SimpleAF" },
  { href: "#features", label: "Hardware" },
  { href: "#path", label: "Path" },
  { href: "#faq", label: "FAQ" },
];

const toneStyles = {
  go: "border-emerald-500/30 bg-emerald-950/40",
  caution: "border-amber-400/30 bg-amber-950/35",
  stop: "border-red-400/30 bg-red-950/35",
};

const statusStyles: Record<string, string> = {
  Works: "text-emerald-300",
  Likely: "text-emerald-200",
  Plausible: "text-amber-200",
  Uncertain: "text-amber-200",
  "Extra work": "text-amber-200",
  Unlikely: "text-red-300",
  DIY: "text-amber-200",
  No: "text-red-300",
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
              Host feasibility
            </p>
            <h1 className="max-w-2xl text-3xl font-semibold tracking-tight text-balance sm:text-4xl">
              Custom Debian and SimpleAF on a Mellow Fly Lite V2.1
            </h1>
            <p className="max-w-2xl text-sm leading-6 text-muted-foreground sm:text-base">
              Short answer: the board can run Debian. SimpleAF can run on that
              Debian. Stock FlyOS-FAST cannot host SimpleAF, and “every Fly
              connector still works” is a separate, harder job than printing.
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
        <section id="verdict" className="space-y-6">
          <SectionHeading
            kicker="01"
            title="Verdict"
            text="Three facts decide this. Everything else is implementation detail."
          />
          <div className="grid gap-4 lg:grid-cols-3">
            {verdicts.map((item) => (
              <Card key={item.title} className={toneStyles[item.tone]}>
                <CardHeader>
                  <Badge variant="outline" className="w-fit capitalize">
                    {item.tone === "go"
                      ? "Possible"
                      : item.tone === "stop"
                        ? "Blocked"
                        : "Qualified"}
                  </Badge>
                  <CardTitle className="text-lg">{item.title}</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="leading-6 text-muted-foreground">{item.body}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </section>

        <section id="board" className="space-y-6">
          <SectionHeading
            kicker="02"
            title="What this board actually is"
            text="The Fly Lite V2.1 is a Klipper host. It is not the printer motion controller, and it is not a Raspberry Pi."
          />
          <div className="grid gap-4 lg:grid-cols-[1.1fr_0.9fr]">
            <Card>
              <CardHeader>
                <CardTitle>Fly-Pi-lite2.1</CardTitle>
                <CardDescription>
                  Official Mellow specs. Same silicon generation as Orange Pi
                  Lite / One, with Fly’s own power, display, and Wi-Fi wiring.
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
                <CardTitle>What it is not</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4 text-sm leading-6 text-muted-foreground">
                <p>
                  It is not an STM32 printer board. Steppers, heaters, and endstops
                  still live on a separate MCU that you flash with Klipper and
                  plug in over USB.
                </p>
                <p>
                  It is not Pi-compatible at the image level. Raspberry Pi OS
                  will not boot. You need an Allwinner H3 / sunxi userspace:
                  Armbian, Orange Pi Debian, or DietPi for H3.
                </p>
                <p>
                  It has no Ethernet jack and only 512 MB of RAM. Those two
                  limits shape every realistic SimpleAF install more than the
                  Debian question does.
                </p>
              </CardContent>
            </Card>
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <Fact icon={Cpu} label="SoC family" value="sun8i-H3, 32-bit" />
            <Fact icon={MemoryStick} label="RAM ceiling" value="512 MB DDR3" />
            <Fact icon={Wifi} label="Onboard radio" value="2.4 GHz only" />
            <Fact icon={HardDrive} label="Install media" value="MicroSD swap" />
          </div>
        </section>

        <section id="simpleaf" className="space-y-6">
          <SectionHeading
            kicker="03"
            title="Why FlyOS-FAST and SimpleAF fight"
            text="SimpleAF for RPi wants a boring Debian box. FlyOS-FAST is a locked appliance image built so beginners never touch apt."
          />
          <Card>
            <CardContent className="px-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="pl-4">FlyOS-FAST</TableHead>
                    <TableHead className="pr-4">SimpleAF for RPi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {flyosBlockers.map((row) => (
                    <TableRow key={row.fly}>
                      <TableCell className="pl-4 align-top text-muted-foreground">
                        {row.fly}
                      </TableCell>
                      <TableCell className="pr-4 align-top">
                        {row.simple}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
          <div className="grid gap-4 md:grid-cols-2">
            <Card className="border-red-400/25">
              <CardHeader className="flex-row items-start gap-3">
                <ShieldAlert className="mt-0.5 size-5 text-red-300" />
                <div>
                  <CardTitle>Do not install on the current image</CardTitle>
                  <CardDescription className="mt-2 leading-6">
                    Pellcorp’s docs also ban Mainsail OS and any host already
                    set up with KIAUH. FlyOS-FAST fails for both reasons: it is
                    not a normal Debian userspace, and it already has the
                    Klipper stack.
                  </CardDescription>
                </div>
              </CardHeader>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle>What SimpleAF will accept</CardTitle>
                <CardDescription className="leading-6">
                  Debian 11, 12, or 13 on a Pi-like SBC: Raspberry Pi OS Lite,
                  Orange Pi Debian, DietPi, and Armbian are in scope. Ubuntu
                  might work. You must log in as a normal user with sudo, not
                  root.
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
        </section>

        <section id="ram" className="space-y-6">
          <SectionHeading
            kicker="04"
            title="512 MB is the real limiter"
            text="SimpleAF is tested on Pi 3 and up. A Pi 3 has 1 GB. The Lite has half of that and a slower Cortex-A7."
          />
          <div className="grid gap-4 lg:grid-cols-[0.9fr_1.1fr]">
            <Card>
              <CardHeader>
                <CardTitle>What to run</CardTitle>
                <CardDescription>
                  A lean host can print. A full SimpleAF extras list will swap
                  itself to death.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-3 text-sm leading-6">
                <p>
                  Keep Debian CLI-only. Add zram plus a 1 GB swap file. Skip
                  Crowsnest. Skip KlipperScreen. Let Fluidd or Mainsail be the
                  UI and ignore the second one.
                </p>
                <p className="text-muted-foreground">
                  Input shaper and NumPy will still fit if you are not also
                  encoding a camera. Resonance measurements should be done, then
                  the accelerometer unplugged.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="px-0">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="pl-4">Process</TableHead>
                      <TableHead className="pr-4">Budget</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {ramBudget.map((row) => (
                      <TableRow key={row.item}>
                        <TableCell
                          className={`pl-4 ${row.warn ? "text-amber-200" : ""}`}
                        >
                          {row.item}
                        </TableCell>
                        <TableCell
                          className={`pr-4 font-mono text-xs ${row.warn ? "text-amber-200" : "text-muted-foreground"}`}
                        >
                          {row.size}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </div>
        </section>

        <section id="features" className="space-y-6">
          <SectionHeading
            kicker="05"
            title="Full functionality, feature by feature"
            text="“Debian boots” and “every Fly connector works” are different projects. SimpleAF only needs USB to the MCU, a network path, and enough RAM."
          />
          <div className="overflow-x-auto rounded-xl ring-1 ring-foreground/10">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="min-w-44 pl-4">Feature</TableHead>
                  <TableHead>FlyOS-FAST</TableHead>
                  <TableHead>Generic H3 Armbian</TableHead>
                  <TableHead>Armbian + Fly DTB</TableHead>
                  <TableHead className="min-w-72 pr-4">Notes</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {features.map((row) => (
                  <TableRow key={row.name}>
                    <TableCell className="pl-4 font-medium">{row.name}</TableCell>
                    <TableCell className={statusStyles[row.flyos]}>
                      {row.flyos}
                    </TableCell>
                    <TableCell className={statusStyles[row.generic]}>
                      {row.generic}
                    </TableCell>
                    <TableCell className={statusStyles[row.flyDtb]}>
                      {row.flyDtb}
                    </TableCell>
                    <TableCell className="pr-4 text-muted-foreground">
                      {row.note}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <div className="grid gap-3 sm:grid-cols-3">
            <Fact icon={Usb} label="Needed for SimpleAF" value="USB MCU + network" />
            <Fact icon={Router} label="Reliable network" value="USB dongle first" />
            <Fact icon={Monitor} label="Fly screens" value="Optional later work" />
          </div>
        </section>

        <section id="path" className="space-y-6">
          <SectionHeading
            kicker="06"
            title="Pick a path"
            text="There is a clean SimpleAF path, a hardware-fidelity path, and a path you should skip."
          />
          <Tabs defaultValue="realistic">
            <TabsList className="mb-4 flex h-auto w-full flex-wrap justify-start gap-1">
              <TabsTrigger value="realistic">Realistic SimpleAF</TabsTrigger>
              <TabsTrigger value="fidelity">Full Fly hardware</TabsTrigger>
              <TabsTrigger value="skip">Do not do this</TabsTrigger>
              <TabsTrigger value="other">Different host</TabsTrigger>
            </TabsList>
            <TabsContent value="realistic">
              <PathCard
                title="Second SD card, Armbian Bookworm, USB network"
                body="This is the only path that matches SimpleAF’s documented OS list without fighting FlyOS. You accept that the FPC screen and maybe onboard Wi-Fi wait until after the printer prints."
                points={[
                  "Flash Armbian Debian 12 CLI for Orange Pi Lite or Orange Pi One.",
                  "First login over Type-C serial or a USB Ethernet adapter.",
                  "Create user fly or pi with passwordless sudo.",
                  "Install SimpleAF against your motion-board printer.cfg.",
                  "Leave Crowsnest and KlipperScreen off.",
                ]}
              />
            </TabsContent>
            <TabsContent value="fidelity">
              <PathCard
                title="Bring Fly’s device tree onto Armbian"
                body="This is how people made stock-feeling Armbian images for Fly Gemini and Fly-Pi. It is the right approach if you insist on onboard Wi-Fi and the official TFT. It is not required for SimpleAF."
                points={[
                  "Dump the official H3 FlyOS image and copy DTB, overlays, and Wi-Fi firmware.",
                  "Start from Mellow’s older flypi Armbian fork or the Gemini community patches as a reference, not a drop-in.",
                  "Freeze kernel and u-boot once Wi-Fi and USB work. Updating those packages can undo the board support.",
                  "Only then create a non-root user and run SimpleAF.",
                ]}
              />
            </TabsContent>
            <TabsContent value="skip">
              <PathCard
                title="SimpleAF on FlyOS-FAST, or KIAUH on FAST, or Pi OS"
                body="These fail for structural reasons, not because you missed a flag."
                points={[
                  "FlyOS-FAST has no apt and only root. The installer will not run.",
                  "KIAUH plus SimpleAF is explicitly unsupported even on a normal Pi.",
                  "Raspberry Pi OS cannot boot an H3.",
                  "Do not power the Lite from the printer MCU. Mellow says that can damage the board, OS aside.",
                ]}
              />
            </TabsContent>
            <TabsContent value="other">
              <PathCard
                title="Keep SimpleAF, change the host"
                body="If the goal is SimpleAF rather than “this exact $25 board must survive,” a Pi 4, Pi 3B+, or 1 GB Orange Pi is the low-friction answer. The Lite stays a working FlyOS spare."
                points={[
                  "SimpleAF is tested on Pi 3, 4, and 5, 32- or 64-bit Lite images.",
                  "Orange Pi Debian and DietPi Bookworm are also documented.",
                  "Your printer MCU config moves with you. The host is interchangeable.",
                  "Use the Lite later if you want FlyOS and KlipperScreen without SimpleAF.",
                ]}
              />
            </TabsContent>
          </Tabs>
        </section>

        <section id="plan" className="space-y-6">
          <SectionHeading
            kicker="07"
            title="Lean install plan"
            text="High-level order of operations if you stay on the Lite. Use a spare card. Do not flash over the only working FlyOS install you have."
          />
          <ol className="grid gap-3">
            {planSteps.map((step, index) => (
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
                <Cable className="size-4 text-primary" />
                Installer shape
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <pre className="overflow-x-auto rounded-lg bg-black/40 p-4 font-mono text-xs leading-6 text-amber-100">
                {`sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/pellcorp/creality.git ~/pellcorp
~/pellcorp/installer.sh --install --printer ~/my-printer.cfg --probe <probe>`}
              </pre>
              <p className="text-sm leading-6 text-muted-foreground">
                Run that as the non-root user.{" "}
                <code className="rounded bg-muted px-1.5 py-0.5 font-mono text-xs">
                  my-printer.cfg
                </code>{" "}
                is the motion board, in one file: mcu, steppers, extruder, bed,
                fans. No probe section; SimpleAF adds that from{" "}
                <code className="rounded bg-muted px-1.5 py-0.5 font-mono text-xs">
                  --probe
                </code>
                . There is no Fly Lite printer definition because the Lite is
                not a printer board.
              </p>
            </CardContent>
          </Card>
        </section>

        <section id="decide" className="space-y-6">
          <SectionHeading
            kicker="08"
            title="Should you do it?"
            text="Use this if you want a recommendation instead of reading the tables again."
          />
          <DecisionHelper />
        </section>

        <section id="faq" className="space-y-6">
          <SectionHeading kicker="09" title="FAQ" />
          <Card>
            <CardContent>
              <Accordion>
                {faqs.map((item) => (
                  <AccordionItem key={item.q} value={item.q}>
                    <AccordionTrigger>{item.q}</AccordionTrigger>
                    <AccordionContent className="text-sm leading-6 text-muted-foreground">
                      {item.a}
                    </AccordionContent>
                  </AccordionItem>
                ))}
              </Accordion>
            </CardContent>
          </Card>
        </section>

        <section id="sources" className="space-y-4 pb-8">
          <SectionHeading
            kicker="10"
            title="Sources"
            text="This guide is a reading of public docs, not a Mellow or SimpleAF endorsement that the Lite is a supported SimpleAF target."
          />
          <ul className="grid gap-2 sm:grid-cols-2">
            {sources.map((source) => (
              <li key={source.href}>
                <a
                  href={source.href}
                  target="_blank"
                  rel="noreferrer"
                  className="block rounded-lg border border-border bg-card px-3 py-3 text-sm transition-colors hover:border-primary/50"
                >
                  {source.label}
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

function PathCard({
  title,
  body,
  points,
}: {
  title: string;
  body: string;
  points: string[];
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>{title}</CardTitle>
        <CardDescription className="leading-6">{body}</CardDescription>
      </CardHeader>
      <CardContent>
        <ul className="space-y-2 text-sm leading-6 text-muted-foreground">
          {points.map((point) => (
            <li key={point} className="flex gap-2">
              <span className="mt-2 size-1.5 shrink-0 rounded-full bg-primary" />
              <span>{point}</span>
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}
