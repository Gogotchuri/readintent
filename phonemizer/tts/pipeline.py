import dataclasses
from typing import List

from tts.vocab import VOCAB
from kokoro import KPipeline

@dataclasses.dataclass
class TokenMeta:
    text: str
    phoneme_len: int
    has_whitespace: bool

@dataclasses.dataclass
class PhonemizerResult:
    """PhonemizerResult describing the array data type of the pipeline result"""
    graphemes: str
    phonemes: str
    token_ids: List[int]
    token_meta: List[TokenMeta]

    # json
    def to_dict(self):
        return {
            "graphemes": self.graphemes,
            "phonemes": self.phonemes,
            "token_ids": self.token_ids,
            "token_meta": [dataclasses.asdict(tm) for tm in self.token_meta],
        }

class PhonemizerPipeline:
    def __init__(self, pipeline: KPipeline):
        # model=False = "quiet" mode — only does G2P, no model loaded
        self.pipeline = pipeline

    def generate_phonemes(self, text:str, voice='af_heart') -> List[PhonemizerResult]:
        final_result: List[PhonemizerResult] = []
        for result in self.pipeline(text, voice):
            # Add paddings to token_ids
            token_ids = [0] + [VOCAB[c] for c in result.phonemes if c in VOCAB] + [0]

            # Build per-word metadata so the Flutter side can reconstruct
            # word-level timestamps from the model's pred_dur output.
            token_meta: List[TokenMeta] = []
            if result.tokens:
                for tok in result.tokens:
                    phoneme_len = len([c for c in (tok.phonemes or '') if c in VOCAB])
                    if phoneme_len > 0 or tok.text:
                        token_meta.append(TokenMeta(
                            text=tok.text or '',
                            phoneme_len=phoneme_len,
                            has_whitespace=bool(tok.whitespace),
                        ))

            final_result.append(PhonemizerResult(
                graphemes=result.graphemes,
                phonemes=result.phonemes,
                token_ids=token_ids,
                token_meta=token_meta,
            ))

        return final_result
