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
    id: "spareCard",
    prompt: "Do you have a second MicroSD card so FlyOS stays intact?",
    options: [
      { id: "yes", label: "Yes, spare card" },
      { id: "no", label: "Only one card" },
    ],
  },
  {
    id: "console",
    prompt: "How will you talk to the board on the first boot?",
    options: [
      { id: "serial", label: "Type-C serial" },
      { id: "dongle", label: "USB Ethernet / USB Wi-Fi" },
      { id: "hope", label: "Onboard Wi-Fi only" },
    ],
  },
  {
    id: "display",
    prompt: "Which display has to work in the first week?",
    options: [
      { id: "none", label: "None, SSH is enough" },
      { id: "hdmi", label: "FPC-HDMI" },
      { id: "tft", label: "Official FPC-TFT" },
    ],
  },
] as const;

type AnswerId = (typeof questions)[number]["id"];
type Answers = Partial<Record<AnswerId, string>>;

function outcome(answers: Answers) {
  if (answers.spareCard === "no") {
    return {
      tone: "stop" as const,
      title: "Buy another card before you flash anything",
      body: "The Lite has no eMMC. One card is one OS. Image a spare, leave the working FlyOS card on the shelf, then continue.",
    };
  }

  if (answers.console === "hope") {
    return {
      tone: "caution" as const,
      title: "Do not make onboard Wi-Fi your only login path",
      body: "It might come up on the Orange Pi Lite image. If it does not, you have a silent board. Get Type-C serial or a USB network dongle working first, then chase MMC1.",
    };
  }

  if (answers.display === "tft") {
    return {
      tone: "caution" as const,
      title: "Boot Debian headless, then steal the TFT from FlyOS",
      body: "Flash Armbian Orange Pi Lite CLI. Prove USB and a console. Extract the official H3 DTB and look at SPI plus GPIO fragments before you write a TFT overlay. A guessed pinmux can hold reset or backlight in a bad state.",
    };
  }

  if (answers.display === "hdmi") {
    return {
      tone: "go" as const,
      title: "Orange Pi Lite image, then turn HDMI on",
      body: "The H3 HDMI block is already described in the Lite DTS. After you have a console, connect only the FPC-HDMI cable and check /sys/class/drm. If the connector stays disconnected, the FPC pinout differs and you need the Fly DTB.",
    };
  }

  if (
    answers.spareCard === "yes" &&
    (answers.console === "serial" || answers.console === "dongle") &&
    answers.display === "none"
  ) {
    return {
      tone: "go" as const,
      title: "This is the right first week",
      body: "Armbian Debian 12 CLI for Orange Pi Lite on the spare card. Independent 5 V. Type-C serial or a USB dongle. Run scripts/first-boot-checks.sh. Treat Wi-Fi and displays as the next experiment, not the boot requirement.",
    };
  }

  return {
    tone: "caution" as const,
    title: "Answer the rest",
    body: "The board can run Debian. The order you enable hardware decides whether you get a login or a paperweight.",
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
        <CardTitle className="text-xl">Where to start</CardTitle>
        <CardDescription>
          Three questions. This picks the first image and the first test, not
          the final desktop.
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
                    className="h-auto min-h-8 justify-start whitespace-normal sm:flex-1"
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
          <div className="mb-2 flex flex-wrap items-center gap-2">
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
