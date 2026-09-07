"use client";

import { useState } from "react";
import { ChevronDown, ExternalLink } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
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
      "Open the Orange Pi Lite board page or use the Trixie Minimal short URL below.",
      "Flash with Armbian Imager, Raspberry Pi Imager, Etcher, or dd. This is a normal .img.xz.",
      "First boot on the spare card only. Independent 5 V.",
      "Complete the Armbian first-run user. Keep that user; do not live as root.",
    ],
    links: downloads.debian,
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
  },
] as const;

export function ImageTabs() {
  const [active, setActive] = useState<(typeof imageTabs)[number]["id"]>(
    "armbian"
  );
  const tab = imageTabs.find((item) => item.id === active) ?? imageTabs[0];

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-2">
        {imageTabs.map((item) => (
          <Button
            key={item.id}
            type="button"
            variant={item.id === active ? "default" : "outline"}
            className="h-auto min-h-8"
            aria-pressed={item.id === active}
            onClick={() => setActive(item.id)}
          >
            {item.label}
          </Button>
        ))}
      </div>
      <Card>
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
    </div>
  );
}

export function FaqList() {
  const [open, setOpen] = useState<string | null>(null);

  return (
    <div className="divide-y divide-border">
      {faqs.map((item) => {
        const expanded = open === item.q;
        return (
          <div key={item.q}>
            <button
              type="button"
              className="flex w-full items-start justify-between gap-3 py-3 text-left text-sm font-medium"
              aria-expanded={expanded}
              onClick={() => setOpen(expanded ? null : item.q)}
            >
              <span>{item.q}</span>
              <ChevronDown
                className={`mt-0.5 size-4 shrink-0 text-muted-foreground transition-transform ${expanded ? "rotate-180" : ""}`}
              />
            </button>
            {expanded ? (
              <p className="pb-3 text-sm leading-6 text-muted-foreground">
                {item.a}
              </p>
            ) : null}
          </div>
        );
      })}
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
