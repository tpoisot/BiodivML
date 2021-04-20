<!DOCTYPE html>
<html>
<head>
    {{#:title}}<title>{{:title}}</title>{{/:title}}
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
    <style>
        @import url(https://fonts.googleapis.com/css?family=Barlow);
        @import url(https://fonts.googleapis.com/css?family=Barlow+Semi+Condensed);
        @import url(https://fonts.googleapis.com/css?family=Ubuntu+Mono:400,700,400italic);
        
        body { font-family: 'Barlow'; }
        h1, h2, h3 {
            font-family: 'Barlow Semi Condensed';
            font-weight: normal;
        }
        .remark-code, .remark-inline-code { font-family: 'Ubuntu Mono'; }
        .remark-slide-content {
            padding: 1em;
        }
    </style>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.10.0-rc.1/dist/katex.min.css"
        integrity="sha384-D+9gmBxUQogRLqvARvNLmA9hS2x//eK1FhVb9PiU86gmcrBrJAQT8okdJ4LMp2uv" crossorigin="anonymous" />
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.10.0-rc.1/dist/katex.min.js"
        integrity="sha384-483A6DwYfKeDa0Q52fJmxFXkcPCFfnXMoXblOkJ4JcA8zATN6Tm78UNL72AKk+0O"
        crossorigin="anonymous"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.10.0-rc.1/dist/contrib/auto-render.min.js"
        integrity="sha384-yACMu8JWxKzSp/C1YV86pzGiQ/l1YUfE8oPuahJQxzehAjEt2GiQuy/BIvl9KyeF"
        crossorigin="anonymous"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function () {
            renderMathInElement(document.body, {
                delimiters: [
                    { left: "$$", right: "$$", display: true },
                    { left: "$", right: "$", display: false }
                ]
            });
        });
    </script>

</head>
<body>
    
<textarea id="source">
        
class: center, middle

# {{:title}}

---

{{{ :body }}}

</textarea>
    
    <script src="https://remarkjs.com/downloads/remark-latest.min.js">
    </script>
    <script>
        var slideshow = remark.create({
            ratio: '16:9',
            slideNumberFormat: 'Slide %current% of %total%',
            countIncrementalSlides: false
        });
    </script>
</body>
</html>