# New K53 Practice Test — Question Bank

This folder stores the first 15 questions supplied for the new Coki K53 practice test.

## Files
- `questions.json`: learner-facing question wording, statements, options, and image paths.
- `answer-key.json`: correct answers, kept separate from the learner question data.
- `images/`: clean crops of the original supplied sign/diagram/illustration.

## Image handling
- Preserve the original visual supplied for the question.
- Remove red answer highlighting from the source screenshot.
- Remove red annotation arrows used only to point out the relevant feature.
- Preserve red shapes/markings that are part of the original sign or illustration.
- Do not redraw, replace, or AI-generate supplied visuals.

## Status
Draft question bank only. This commit does not change the existing test player, existing tests, or deployment configuration. New questions can be appended using the same schema.
