import { Badge } from "@/components/ui/badge";
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
      { id: "hdmi", label: "HDMI + USB keyboard" },
      { id: "file", label: "fly-net.txt on the card" },
      { id: "hope", label: "Onboard Wi-Fi, no file" },
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

export function DecisionHelper() {
  return (
    <Card className="border-primary/20">
      <CardHeader>
        <CardTitle className="text-xl">Where to start</CardTitle>
        <CardDescription>
          Three questions. This picks the Lite 2.1 first login, not the final
          custom image.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form
          className="space-y-6
            [&_.out-stop]:hidden
            [&_.out-hope]:hidden
            [&_.out-tft]:hidden
            [&_.out-hdmi]:hidden
            [&_.out-go]:hidden
            has-[[name=spareCard][value=no]:checked]:[&_.out-stop]:block
            has-[[name=spareCard][value=no]:checked]:[&_.out-default]:hidden
            has-[[name=console][value=hope]:checked]:not-has-[[name=spareCard][value=no]:checked]:[&_.out-hope]:block
            has-[[name=console][value=hope]:checked]:not-has-[[name=spareCard][value=no]:checked]:[&_.out-default]:hidden
            has-[[name=display][value=tft]:checked]:not-has-[[name=spareCard][value=no]:checked]:not-has-[[name=console][value=hope]:checked]:[&_.out-tft]:block
            has-[[name=display][value=tft]:checked]:not-has-[[name=spareCard][value=no]:checked]:not-has-[[name=console][value=hope]:checked]:[&_.out-default]:hidden
            has-[[name=display][value=hdmi]:checked]:not-has-[[name=spareCard][value=no]:checked]:not-has-[[name=console][value=hope]:checked]:[&_.out-hdmi]:block
            has-[[name=display][value=hdmi]:checked]:not-has-[[name=spareCard][value=no]:checked]:not-has-[[name=console][value=hope]:checked]:[&_.out-default]:hidden
            has-[[name=spareCard][value=yes]:checked]:has-[[name=display][value=none]:checked]:has-[[name=console][value=serial]:checked]:[&_.out-go]:block
            has-[[name=spareCard][value=yes]:checked]:has-[[name=display][value=none]:checked]:has-[[name=console][value=serial]:checked]:[&_.out-default]:hidden
            has-[[name=spareCard][value=yes]:checked]:has-[[name=display][value=none]:checked]:has-[[name=console][value=hdmi]:checked]:[&_.out-go]:block
            has-[[name=spareCard][value=yes]:checked]:has-[[name=display][value=none]:checked]:has-[[name=console][value=hdmi]:checked]:[&_.out-default]:hidden
            has-[[name=spareCard][value=yes]:checked]:has-[[name=display][value=none]:checked]:has-[[name=console][value=file]:checked]:[&_.out-go]:block
            has-[[name=spareCard][value=yes]:checked]:has-[[name=display][value=none]:checked]:has-[[name=console][value=file]:checked]:[&_.out-default]:hidden
          "
        >
          {questions.map((question) => (
            <fieldset key={question.id} className="space-y-2">
              <legend className="text-sm font-medium">{question.prompt}</legend>
              <div className="flex flex-col gap-2 sm:flex-row">
                {question.options.map((option) => (
                  <label
                    key={option.id}
                    className="flex-1 cursor-pointer rounded-lg border border-border bg-background px-3 py-1.5 text-sm font-medium hover:bg-muted has-[:checked]:border-transparent has-[:checked]:bg-primary has-[:checked]:text-primary-foreground"
                  >
                    <input
                      type="radio"
                      name={question.id}
                      value={option.id}
                      className="sr-only"
                    />
                    {option.label}
                  </label>
                ))}
              </div>
            </fieldset>
          ))}

          <div className="out-default rounded-xl border border-amber-400/40 bg-amber-400/10 px-4 py-4 text-amber-100">
            <Badge variant="outline" className="mb-2 border-current text-current">
              Answer the rest
            </Badge>
            <p className="text-sm leading-6 opacity-90">
              The board can run Debian. The order you enable hardware decides
              whether you get a login or a paperweight.
            </p>
          </div>
          <div className="out-stop rounded-xl border border-red-400/40 bg-red-500/10 px-4 py-4 text-red-100">
            <Badge variant="outline" className="mb-2 border-current text-current">
              Buy another card before you flash anything
            </Badge>
            <p className="text-sm leading-6 opacity-90">
              The Lite has no eMMC. One card is one OS. Image a spare, leave
              the working FlyOS card on the shelf, then continue.
            </p>
          </div>
          <div className="out-hope rounded-xl border border-amber-400/40 bg-amber-400/10 px-4 py-4 text-amber-100">
            <Badge variant="outline" className="mb-2 border-current text-current">
              Do not make onboard Wi-Fi your only login path
            </Badge>
            <p className="text-sm leading-6 opacity-90">
              Write first-boot/fly-net.txt onto the card, or use Type-C serial /
              HDMI+USB. A silent radio with no console is a paperweight.
            </p>
          </div>
          <div className="out-tft rounded-xl border border-amber-400/40 bg-amber-400/10 px-4 py-4 text-amber-100">
            <Badge variant="outline" className="mb-2 border-current text-current">
              Boot Debian headless, then steal the TFT from FlyOS
            </Badge>
            <p className="text-sm leading-6 opacity-90">
              Flash Armbian Orange Pi Lite CLI. Prove USB and a console. Extract
              the official H3 DTB and look at SPI plus GPIO fragments before you
              write a TFT overlay.
            </p>
          </div>
          <div className="out-hdmi rounded-xl border border-emerald-500/40 bg-emerald-500/10 px-4 py-4 text-emerald-200">
            <Badge variant="outline" className="mb-2 border-current text-current">
              Orange Pi Lite image, then turn HDMI on
            </Badge>
            <p className="text-sm leading-6 opacity-90">
              The H3 HDMI block is already described in the Lite DTS. After you
              have a console, connect only the FPC-HDMI cable and check
              /sys/class/drm.
            </p>
          </div>
          <div className="out-go rounded-xl border border-emerald-500/40 bg-emerald-500/10 px-4 py-4 text-emerald-200">
            <Badge variant="outline" className="mb-2 border-current text-current">
              This is the right first week
            </Badge>
            <p className="text-sm leading-6 opacity-90">
              Armbian Debian 13 Trixie Minimal CLI for Orange Pi Lite on the
              spare card. Independent 5 V. Type-C serial, HDMI+USB, or
              fly-net.txt. Run scripts/first-boot-checks.sh.
            </p>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
