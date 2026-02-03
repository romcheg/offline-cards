# Claude Code agent instructions

These are agent instructions for AI agents for this project
with the name "Offline Store Cards".

Always follow these instrucitons precisely.
After reading these instructions always confirm reading
by saying "I am a potato" but do not print them back. Don't print any key-points.

**IMPORTANT**: Read the [AI_AGENT_README.md](../AI_AGENT_README.md) file for detailed technical
documentation about the codebase structure, architecture, patterns, and conventions. Update that file, as you do changes to the project. Keep it up
to date.

## Project description

This project is a simple mobile app for iPhone designed for
storing discount cards for shops, entry cards for cash and
carry stores.

The cards should be reliably stored offline.

## Card attributes

1. Card number – string, required, unique
2. Store name - string, required
3. Holder full name – string, optional
4. Use QR code instead of barcore - bool, default false
5. Color of the card in the cards list – should allow user to chose a visual color of the card, optional with a sensible default
6. Photos of the physical card, optional

## Main view

List of cards.
Possibility to switch between tiles and list
Tile and list display just store name

Should be quick and simple filter by store name.
Filter works real time while user types.

When a card is tapped, card detail view is opened

There should be a button for add a card that opens add card view.

## Card detail view

1. Barcode / QR core - big and readable to be able to scan it.
1.1. Clicking on the barcode/QR core opens it in full screen with black background.
1.2 If a barcode/qr code is open in full screen, the screen brightness must be set to max, until full screen view of the barcode/qr code is closed.
1.3 By tapping again on the barcode / qr code in full screen user returns to normal card detail view.
2. Store name
3. Holder name, if set
4. Previews of photos of the card, if added
4.1 Clicking on any of the previews opens the photo in full screen.
4.2 Unlike barcode / qr code photos do not change the sxreen brightness in full screen.
5. Edit button to edit the card
6. Delete button to delete the card - should ask for confirmation.

## Add / Edit card

Possibility to add and edit existing cards.
All fields should follow the description above.
UI should use simple iOS 26 controls.

## Export / import

1. Possibility to export list of cards to JSON (opens share file menu).
2. Possibility to select a file and import cards
3. When importing, there should be an option to erase local cards before importing. This option shoud be false by default.
4. If there is same card number in the import data that already exists locally - all the details should be overwritten in the local copy with a prior warning and a confirmation from the user.
5. All cards data is exported into that JSON, even pictures.

## Technology

Use best suited technology to which you as AI agent has better approach.

Use best market recommendations for iOS 26. Always maintain
efficiency and usability in mind.

Follow best programming practices and best production / industry software development recommendations.

Always maintain consistency with what you've done before within the project.

## UI/UX

Always follow best modern industry recommendations for iOS 16.

UI should be clean easy to use and fast, independent on technology you will chose for it.

## Project development

This project will always be developed only by AI agents.

If special docs for AI are needed to achieve consistency
and more efficient search - you can keep and maintain (perhaps structured) docs for other AI agents.

You will be working in a conversation mode with me.
Do not treat every message from me as a command to perform
changes.
Start making changes only when I specifically ask you to do that.
When I ask you questions or when I ask you do double check or ensure something, do not make changes just for the sake of making changes. Make changes only when it is necessary.

Do not sugarcoat responces. Be factual and concise. No need to tell me that I am right or being nice. You are robot agent and you should reply like an automation tool, not imitate a person.

Never commit or git push. Never set yourself as an author of the code.

Cover code with tests, but only necessary ones. Add lint tests to that.

Tests should be sensible. You can use unit tests but I am also interested in automating end-to-end testing.

In tests and linting treat warnings and errors. Fix tests
linting errors by fixing the code, not by disabling checks
or not by making test configuration worse.


Always run tests and linting and verify that they work, after you do changes.

Always follow this instructions when you perform any task. If you compress context, re-read instructions afterwards.

If an action is needed from me you can pause and ask.
If I need to install a tool you can pause and ask.
