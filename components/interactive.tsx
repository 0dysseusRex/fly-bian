import { ChevronDown, ExternalLink } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { downloads, faqs, type GuideLink } from "@/lib/guide";

const imageTabs = [
  {
    id: "armbian",
    label: "Armbian (recommended)",
    title: "Armbian Debian 13 Trixie Minimal CLI, board = orangepilite",
    body: "This is the current public image: Debian userspace, current sunxi kernel, overlays via armbian-add-overlay. Skip the Ubuntu Xfce build on the same page.",
    points: [
      "Open the Orange Pi Lite board page and take Debian 13 Trixie Minimal CLI. Do not use the Trixie_current_minimal short URL (it is a file download).",
      "Flash with Armbian Imager, Raspberry Pi Imager, Etcher, or dd. This is a normal .img.xz.",
      "Remount the FAT boot partition. Edit first-boot/fly-net.txt and run scripts/prepare-sd.sh.",
      "First boot on the spare card only. Independent 5 V. This image has no FAT boot partition — serial past U-Boot is the login. See docs/lite21-bringup.md.",
      "Complete the Armbian first-run user. Keep that user; do not live as root.",
    ],
    links: downloads.debian,
    inputClass: "peer/armbian",
    panelClass: "hidden peer-checked/armbian:flex",
    labelClass:
      "peer-checked/armbian:border-transparent peer-checked/armbian:bg-primary peer-checked/armbian:text-primary-foreground peer-checked/armbian:hover:bg-primary/80",
  },
  {
    id: "dietpi",
    label: "DietPi",
    title: "DietPi does not ship an Orange Pi Lite image",
    body: "Their hardware list covers later Orange Pi boards, not this H3 Lite. If you want DietPi later, convert a working Armbian install. Do not hunt a Lite .7z that is not there.",
    points: [
      "Flash Armbian Trixie Minimal first and prove USB plus a console.",
      "Only then consider converting with DietPi’s prep script.",
      "Overlays are easier to keep on Armbian.",
    ],
    links: downloads.build.filter((link) => link.href.includes("dietpi")),
    inputClass: "peer/dietpi",
    panelClass: "hidden peer-checked/dietpi:flex",
    labelClass:
      "peer-checked/dietpi:border-transparent peer-checked/dietpi:bg-primary peer-checked/dietpi:text-primary-foreground peer-checked/dietpi:hover:bg-primary/80",
  },
  {
    id: "custom",
    label: "Custom rebuild",
    title: "Rebuild Armbian as fly-lite-2.1",
    body: "Worth it after the Orange Pi Lite image boots and you have a DTB diff. Copy config/boards/orangepilite.conf, rename the model, and drop in the Fly DTB.",
    points: [
      "Do not start here. You need a known-good UART and USB path first.",
      "BOARD=orangepilite RELEASE=trixie BUILD_DESKTOP=no BUILD_MINIMAL=yes",
      "Freeze kernel and u-boot once the custom DTB works.",
    ],
    links: downloads.build.filter((link) => !link.href.includes("dietpi")),
    inputClass: "peer/custom",
    panelClass: "hidden peer-checked/custom:flex",
    labelClass:
      "peer-checked/custom:border-transparent peer-checked/custom:bg-primary peer-checked/custom:text-primary-foreground peer-checked/custom:hover:bg-primary/80",
  },
  {
    id: "avoid",
    label: "Do not flash",
    title: "Images that will not help",
    body: "Wrong boot chain or the wrong SoC. These waste a card and can look like a dead board.",
    points: [
      "Raspberry Pi OS, Mainsail OS, any bcm2711 image.",
      "Fly Gemini / Fly-Pi H5 community Armbian images.",
      "Orange Pi PC images (Ethernet, different DRAM and USB map).",
      "The FlyOS-FAST image itself if the goal is Debian with apt. Loot it; do not stay on it.",
    ],
    links: [
      ...downloads.flyos.slice(0, 1),
      {
        label: "Fly Gemini community Armbian (method only, wrong SoC)",
        href: "https://github.com/reemo3dp/mellowfly-geminipi-armbian",
      },
    ],
    inputClass: "peer/avoid",
    panelClass: "hidden peer-checked/avoid:flex",
    labelClass:
      "peer-checked/avoid:border-transparent peer-checked/avoid:bg-primary peer-checked/avoid:text-primary-foreground peer-checked/avoid:hover:bg-primary/80",
  },
] as const;

export function ImageTabs() {
  return (
    <div className="flex flex-wrap gap-2">
      {imageTabs.map((tab, index) => (
        <input
          key={`in-${tab.id}`}
          type="radio"
          name="image-tab"
          id={`image-${tab.id}`}
          defaultChecked={index === 0}
          className={`sr-only ${tab.inputClass}`}
        />
      ))}
      {imageTabs.map((tab) => (
        <label
          key={`lb-${tab.id}`}
          htmlFor={`image-${tab.id}`}
          className={`cursor-pointer rounded-lg border border-border bg-background px-3 py-1.5 text-sm font-medium hover:bg-muted ${tab.labelClass}`}
        >
          {tab.label}
        </label>
      ))}
      {imageTabs.map((tab) => (
        <Card key={`pn-${tab.id}`} className={`w-full ${tab.panelClass}`}>
          <CardHeader>
            <Badge variant="outline" className="w-fit">
              {tab.label}
            </Badge>
            <CardTitle>{tab.title}</CardTitle>
            <CardDescription className="leading-6">{tab.body}</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <ul className="space-y-2 text-sm leading-6 text-muted-foreground">
              {tab.points.map((point) => (
                <li key={point} className="flex gap-2">
                  <span className="mt-2 size-1.5 shrink-0 rounded-full bg-primary" />
                  <span>{point}</span>
                </li>
              ))}
            </ul>
            <LinkList links={[...tab.links]} />
          </CardContent>
        </Card>
      ))}
    </div>
  );
}

export function FaqList() {
  return (
    <div className="divide-y divide-border">
      {faqs.map((item) => (
        <details key={item.q} className="group py-1">
          <summary className="flex cursor-pointer list-none items-start justify-between gap-3 py-3 text-left text-sm font-medium [&::-webkit-details-marker]:hidden">
            <span>{item.q}</span>
            <ChevronDown className="mt-0.5 size-4 shrink-0 text-muted-foreground transition-transform group-open:rotate-180" />
          </summary>
          <p className="pb-3 text-sm leading-6 text-muted-foreground">
            {item.a}
          </p>
        </details>
      ))}
    </div>
  );
}

function LinkList({ links }: { links: GuideLink[] }) {
  return (
    <ul className="space-y-3">
      {links.map((link) => (
        <li key={link.href} className="space-y-1">
          <a
            href={link.href}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-1.5 text-sm font-medium text-primary underline-offset-4 hover:underline"
          >
            {link.label}
            <ExternalLink className="size-3.5 shrink-0" />
          </a>
          {link.note ? (
            <p className="text-xs leading-5 text-muted-foreground">{link.note}</p>
          ) : null}
        </li>
      ))}
    </ul>
  );
}
