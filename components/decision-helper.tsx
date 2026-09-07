"use client";

import { useMemo, useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

const questions = [
  {
    id: "keepBoard",
    prompt: "Must the Fly Lite V2.1 stay the Klipper host?",
    options: [
      { id: "yes", label: "Yes, this is the host" },
      { id: "no", label: "I can use another SBC" },
    ],
  },
  {
    id: "screen",
    prompt: "Do you need the official FPC-TFT or FPC-HDMI screen?",
    options: [
      { id: "yes", label: "Yes, the Fly screen has to work" },
      { id: "no", label: "Web UI is enough" },
    ],
  },
  {
    id: "dongle",
    prompt: "Can you use a USB Ethernet or USB Wi-Fi dongle?",
    options: [
      { id: "yes", label: "Yes" },
      { id: "no", label: "Only the onboard 2.4 GHz chip" },
    ],
  },
  {
    id: "camera",
    prompt: "Will you run a webcam stack (Crowsnest)?",
    options: [
      { id: "yes", label: "Yes" },
      { id: "no", label: "No camera" },
    ],
  },
] as const;

type AnswerId = (typeof questions)[number]["id"];
type Answers = Partial<Record<AnswerId, string>>;

function outcome(answers: Answers) {
  if (answers.keepBoard === "no") {
    return {
      tone: "go" as const,
      title: "Use a real Pi-class host for SimpleAF",
      body: "SimpleAF is tested on Pi 3/4/5 and Debian Orange Pi images. A board with 1 GB or more RAM, Ethernet, and a supported image will take less time than teaching the Lite new device trees. Keep the Lite as a spare FlyOS host if you want.",
    };
  }

  if (answers.camera === "yes") {
    return {
      tone: "stop" as const,
      title: "512 MB plus a webcam is a bad fit",
      body: "SimpleAF’s RPi stack already includes Klipper, Moonraker, Nginx, and two web UIs. Crowsnest on 512 MB DDR3 will swap and stall. Drop the camera, or move the host.",
    };
  }

  if (answers.screen === "yes") {
    return {
      tone: "caution" as const,
      title: "Possible, but this is a device-tree project",
      body: "SimpleAF itself does not need the FPC screen. Getting that panel working means extracting Fly overlays from the official H3 image and fighting SPI pinmux. Do that after a lean Debian + USB-network install already prints.",
    };
  }

  if (answers.dongle === "no") {
    return {
      tone: "caution" as const,
      title: "Onboard Wi-Fi is the first thing that may fail",
      body: "A generic Orange Pi Lite Armbian image may or may not talk to Mellow’s SDIO chip. Without a USB dongle you can lose the board after the first reboot. Get a console path working first, then chase the Fly Wi-Fi firmware.",
    };
  }

  if (
    answers.keepBoard === "yes" &&
    answers.screen === "no" &&
    answers.dongle === "yes" &&
    answers.camera === "no"
  ) {
    return {
      tone: "go" as const,
      title: "This is the realistic SimpleAF path on the Lite",
      body: "Flash Armbian Debian 12 CLI on a second SD card, boot with a USB network dongle, create a non-root sudo user, add swap, and install SimpleAF against your printer MCU config. Skip KlipperScreen and the camera. Treat onboard Wi-Fi and the FPC ports as optional later work.",
    };
  }

  return {
    tone: "caution" as const,
    title: "Answer the rest to pin this down",
    body: "The Lite can run Debian. Whether SimpleAF is pleasant depends on RAM, network, and how much Fly hardware you insist on keeping.",
  };
}

const toneClass = {
  go: "border-emerald-500/40 bg-emerald-500/10 text-emerald-200",
  caution: "border-amber-400/40 bg-amber-400/10 text-amber-100",
  stop: "border-red-400/40 bg-red-500/10 text-red-100",
};

export function DecisionHelper() {
  const [answers, setAnswers] = useState<Answers>({});
  const result = useMemo(() => outcome(answers), [answers]);
  const answered = Object.keys(answers).length;

  return (
    <Card className="border-primary/20">
      <CardHeader>
        <CardTitle className="text-xl">Decision helper</CardTitle>
        <CardDescription>
          Four questions. This is the same tradeoff as the rest of the guide,
          compressed.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {questions.map((question) => (
          <div key={question.id} className="space-y-2">
            <p className="text-sm font-medium">{question.prompt}</p>
            <div className="flex flex-col gap-2 sm:flex-row">
              {question.options.map((option) => {
                const active = answers[question.id] === option.id;
                return (
                  <Button
                    key={option.id}
                    type="button"
                    variant={active ? "default" : "outline"}
                    className="justify-start sm:flex-1"
                    onClick={() =>
                      setAnswers((current) => ({
                        ...current,
                        [question.id]: option.id,
                      }))
                    }
                  >
                    {option.label}
                  </Button>
                );
              })}
            </div>
          </div>
        ))}

        <div className={`rounded-xl border px-4 py-4 ${toneClass[result.tone]}`}>
          <div className="mb-2 flex items-center gap-2">
            <Badge variant="outline" className="border-current text-current">
              {answered}/{questions.length} answered
            </Badge>
            <p className="font-medium">{result.title}</p>
          </div>
          <p className="text-sm leading-6 opacity-90">{result.body}</p>
        </div>
      </CardContent>
    </Card>
  );
}
